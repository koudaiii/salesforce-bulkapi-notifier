module SalesforceBulkAPINotifier
  class SalesforceService
    API_VERSION = 47.0
    attr_reader :instance_url

    def initialize
      con = Faraday.new(url: "https://#{SalesforceBulkAPINotifier.salesforce_host}") do |c|
        c.adapter :httpclient
        c.request :json
      end

      # https://help.salesforce.com/articleView?id=remoteaccess_oauth_username_password_flow.htm&language=ja&type=0
      response = con.post("/services/oauth2/token", {
        grant_type: :password,
        username: SalesforceBulkAPINotifier.salesforce_user_id,
        password: SalesforceBulkAPINotifier.salesforce_password,
        client_id: SalesforceBulkAPINotifier.salesforce_client_id,
        client_secret: SalesforceBulkAPINotifier.salesforce_client_secret,
        format: :json,
      })

      data = JSON.parse(response.body)

      @access_token = data['access_token']
      @instance_url = data['instance_url']
    end

    def rest_api_client
      return nil unless @instance_url && @access_token
      @rest_api_client ||=
        Faraday.new(url: @instance_url) do |c|
          c.adapter :httpclient
          c.request :json
          c.headers['Authorization'] = "OAuth #{@access_token}"
          c.headers['Content-Type'] = 'application/json'
          c.headers['charset'] = 'UTF-8'
        end
    end

    # ref. https://developer.salesforce.com/docs/atlas.ja-jp.api_bulk_v2.meta/api_bulk_v2/get_all_jobs.htm
    def get_all_jobs
      res = rest_api_client.get("/services/data/v#{API_VERSION}/jobs/ingest")
      raise res if res.status != 200
      data = JSON.parse(res.body)
      jobs = data['records']
      done = data['done']

      until done
        res = rest_api_client.get(data['nextRecordsUrl'])
        raise res if res.status != 200
        data = JSON.parse(res.body)
        done = data['done']
        jobs += data['records']
      end
      jobs
    end

    # ref. https://developer.salesforce.com/docs/atlas.ja-jp.api_bulk_v2.meta/api_bulk_v2/get_job_info.htm
    def get_job_info(sf_job_id)
      res = rest_api_client.get("/services/data/v#{API_VERSION}/jobs/ingest/#{sf_job_id}")
      raise res if res.status != 200
      JSON.parse(res.body)
    end

    # ref. https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/dome_sobject_user_password.htm
    def get_user_name(user_id)
      res = rest_api_client.get("/services/data/v#{API_VERSION}/sobjects/User/#{user_id}")
      raise res if res.status != 200
      JSON.parse(res.body)['Name']
    end

    def screening_by_time(jobs, started_at)
      jobs.map do |job|
        job if job['systemModstamp'].to_datetime >= started_at
      end.compact
    end

    def annotate(job_info)
      user_name = get_user_name(job_info['createdById'])
      error_rate = ((job_info['numberRecordsFailed'].to_f / job_info['numberRecordsProcessed'].to_f) * 100).floor(2)

      job_status = {success: true, message: "Success", error_rate: error_rate, user_name: user_name}
      if job_info['state'] == 'Failed'
        job_status[:success] = false
        job_status[:message] = "Job state is Failed"
      elsif error_rate >= SalesforceBulkAPINotifier.error_rate && job_info['state'] == "Closed"
        job_status[:success] = false
        job_status[:message] = "Error rate is #{error_rate}%. Error percentage is higher than #{SalesforceBulkAPINotifier.error_rate}%"
      else
      end
      job_status
    end
  end
end
