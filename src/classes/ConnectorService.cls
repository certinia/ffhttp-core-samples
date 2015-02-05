/**
 * Copyright (c) 2014, FinancialForce.com, inc
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, 
 *   are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice, 
 *      this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice, 
 *      this list of conditions and the following disclaimer in the documentation 
 *      and/or other materials provided with the distribution.
 * - Neither the name of the FinancialForce.com, inc nor the names of its contributors 
 *      may be used to endorse or promote products derived from this software without 
 *      specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
 *  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
 *  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL 
 *  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 *  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 *  OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**/
 
/**
 * ConnectorService
 */
public with sharing class ConnectorService implements ffhttp_IConnectorType
{
	//Statics
	public static final Integer EXPIRY_HEADROOM_TIME_SECONDS = 600; //10 minutes
	
	//Instance variables
	public String connectorId { get; set; }
	public Connector__c connector { get;set; }
	
	/**
	 * Constructor
	 */
	public ConnectorService(String connectorId)
	{
		this.connectorId = connectorId;
	}
	public ConnectorService(Connector__c connector)
	{
		this.connector = connector;
	}
	
	/**
	 * Retrieve the connector for the given connectorId
	 *
	 * Note: for separation of concerns consider using a selector pattern.
	 * See https://developer.salesforce.com/page/Apex_Enterprise_Patterns_-_Selector_Layer
	 */
	public Connector__c retrieveConnector()
	{	
		if (connectorId == null)
		{
			return null;
		}
		
		if (connector == null)
		{
			connector = (Connector__c)
			[
				SELECT c.TokenType__c, c.RefreshToken__c, c.RefreshTokenRequested__c, c.Name, c.Id, c.AccessToken__c, 
					   c.AccessTokenRequested__c, c.AccessTokenExpiry__c, c.Active__c, 
					   ConnectorType__r.TokenEndpoint__c, ConnectorType__r.Scope__c, ConnectorType__r.ScopeRequired__c, 
					   ConnectorType__r.RedirectUri__c, ConnectorType__r.Name, ConnectorType__r.Id, 
					   ConnectorType__r.ExtraUrlParameters__c, ConnectorType__r.DeveloperName__c, 
					   ConnectorType__r.ClientSecret__c, ConnectorType__r.ClientId__c, ConnectorType__r.CallbackURL__c, 
					   ConnectorType__r.AuthorizationEndpoint__c
				FROM Connector__c c 
				WHERE c.Id = :connectorId
				LIMIT 1
			];
		}
		return connector;
	}
	
	/**
     * Determines whether the connector is valid.
     * Returns the appropriate error message. 
     */
    public String validateConnector()
    {
    	if (this.connector == null)
        {
        	return 'No connector found.';
        }
        else if (this.connector.AccessToken__c == null)
        {
        	return 'The connector ' + connector.Name + ' has not been authorized.';
        }
        else if (accessTokenExpired())
        {
        	if (connector.RefreshToken__c == null)
        	{
        		return 'The connector ' + connector.Name + ' needs to be reauthorized.';
        	}
        	else
        	{
	        	//In this case the access_token has expired and needs reauthorising.
	        	//Given that we have the refresh token we can use an OAuthClient call to do this.
	        	exchangeCode(connector.RefreshToken__c);
        	}
        }
        
        return null;
    }
    
    /**
     * Check whether the access token has expired.
     * If a token is within 10 minutes of expiring then deal with it as if it has expired.
     */
    private Boolean accessTokenExpired()
    {
    	//If we don't know when the token was requested, or when it will expire, then treat it like it hasn't expired.
    	DateTime accessTokenRequested = connector.AccessTokenRequested__c;
    	Integer accessTokenExpiry = (Integer)connector.AccessTokenExpiry__c;
    	if (accessTokenRequested == null
    	  || accessTokenExpiry == null)
    	{
    		return false;
    	}
    	
    	Integer cutoff = accessTokenExpiry - EXPIRY_HEADROOM_TIME_SECONDS;
    	
    	DateTime dtNow = System.now();
    	DateTime dtExpiry = accessTokenRequested.addSeconds(cutoff);
    	return dtExpiry < dtNow;
    }
    
    public void exchangeCode(String code)
    {
    	connector.AccessTokenRequested__c = System.now();
		connector.RefreshTokenRequested__c = connector.AccessTokenRequested__c;
		
		ffhttp_OAuthClient client = new ffhttp_OAuthClient();
		ffhttp_OAuthClient.ExchangeRefreshTokenRequest request = client.exchangeRefreshTokenRequest(this, code);
		
    	ffhttp_OAuthClient.AccessTokenResponse response = (ffhttp_OAuthClient.AccessTokenResponse)request.execute();
    	connector.AccessToken__c = response.access_token;
	    connector.RefreshToken__c = response.refresh_token;
	    connector.TokenType__c = response.token_type;
	    connector.AccessTokenExpiry__c = response.expires_in;
    }
    
    /**
     * Returns the access token for this connector
     */
	public String getAccessToken()
	{	
		if (validateConnector() != null)
		{
			return null;
		}
		
		return connector.AccessToken__c;
	}

	/**
	 * IConnectorType implementation
	 */
	public String getAuthorizationEndpoint()
	{
		return connector == null ? null : connector.ConnectorType__r.AuthorizationEndpoint__c;
	}
	public String getTokenEndpoint()
	{
		return connector == null ? null : connector.ConnectorType__r.TokenEndpoint__c;
	}
	public String getClientId()
	{
		return connector == null ? null : connector.ConnectorType__r.ClientId__c;
	}
	public String getClientSecret()
	{
		return connector == null ? null : connector.ConnectorType__r.ClientSecret__c;
	}
	public String getRedirectUri()
	{
		return connector == null ? null : connector.ConnectorType__r.RedirectUri__c;
	}
	public String getExtraUrlParameters()
	{
		if (connector == null)
		{ 
			return '';
		}
		
		if (connector.ConnectorType__r.ScopeRequired__c == true)
		{
			return 'scope=' + connector.ConnectorType__r.Scope__c + '&' + connector.ConnectorType__r.ExtraUrlParameters__c;
		}
		
		if (!String.isEmpty(connector.ConnectorType__r.ExtraUrlParameters__c))
		{
			return connector.ConnectorType__r.ExtraUrlParameters__c;
		}
		
		return '';
	}
}
