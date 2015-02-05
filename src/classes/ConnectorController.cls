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
 * ConnectorController
 */
public with sharing class ConnectorController 
{	
	public class ViewState 
	{
		ConnectorService service {get;set;}
		String authCode {get;set;}
		String error {get;set;}
		Boolean dirty {get;set;}
		Boolean authorized {get;set;}
	}

	ViewState ViewState {get;set;}
	
	ffhttp_OAuthClient client = new ffhttp_OAuthClient();

	public ConnectorController(ApexPages.StandardController controller) 
	{
		ViewState = new ViewState();
		ViewState.dirty = false;
		ViewState.authorized = false;

		Id connectorId = getConnectorId(controller);
		if (connectorId == null) 
		{
			error('Missing Connector Id');
		}
		else 
		{
			retrieveConnector(connectorId);
		}

		ViewState.Error = ApexPages.currentPage().getParameters().get('error');
		if (ViewState.Error!=null) 
		{
			error('Authentication error: ' + ViewState.Error);
		}

		ViewState.AuthCode = ApexPages.currentPage().getParameters().get('code');
		if (ViewState.AuthCode != null) 
		{
			try
			{
				exchangeAuthCode();
			}
			catch (Exception ex)
			{
				error('Authentication error: Check the client secret is correct');
			}
		}
	}

	private String getConnectorId(ApexPages.StandardController controller)
	{
		String connectorId;
		String state = ApexPages.currentPage().getParameters().get('state');
		if (state != null) 
		{
			try
			{
				connectorId = (ID) state;
			}
			catch (Exception e) 
			{
				error('Authentication error: Invalid state');		
			}
		}
		else 
		{
			connectorId = controller.getId();
		}
		
		return connectorId;
	}
	
	private void retrieveConnector(String connectorId)
	{
		try
		{
			ConnectorService service = new ConnectorService(connectorId);
			service.retrieveConnector();
			
			ViewState.service = service;
		}
		catch (Exception ex)
		{
			error('Connector record not found');
		}
	}

	public PageReference save() 
	{
		if (ViewState.Service.Connector != null && ViewState.Service.Connector.Id != null) 
		{
			update ViewState.Service.Connector;
		}
		return new ApexPages.StandardController(ViewState.Service.Connector).view();
	}

	public PageReference cancel() 
	{
		if (ViewState.Service.Connector != null && ViewState.Service.Connector.Id != null) 
		{
			return new ApexPages.StandardController(ViewState.Service.Connector).view();
		}
		return new ApexPages.PageReference('/' + Connector__c.SObjectType.getDescribe().getKeyPrefix());
	}

    public PageReference RequestAuthorizationCode()
    {
		if (!isConfigured()) 
		{
			error('Connector type is not configured');
			return null;
		}

		String url = client.generateAuthorizationUrl(ViewState.Service, (String)ViewState.Service.Connector.Id);
    	return new PageReference(url);
    }

	void exchangeAuthCode() 
	{
		if (!isConfigured())
		{
			error('Connector type is not configured');
			return;
		}
		
		ViewState.service.exchangeCode(ViewState.AuthCode, true);
	
	    ViewState.dirty = true;	
	    ViewState.authorized = true;
		
		info('Successful authorization');
	}
	
	/**
	 * Helper methods
	 */
	void error(String message) 
	{
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, message));
	}

	void info(String message) 
	{
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, message));
	}
	
	Boolean isConfigured() 
	{
		return ViewState.Service != null 
		  && ViewState.Service.Connector != null 
		  && ViewState.Service.Connector.ConnectorType__r != null
		  && ViewState.Service.Connector.ConnectorType__r.Name != null;
	}
	
	/**
	 * Gets
	 */
	public String getServiceName() 
	{
		return ViewState.Service ==null ? null : ViewState.Service.Connector.ConnectorType__r.Name;
	}
	public String getRecordName() 
	{
		return ViewState.Service ==null ? null : ViewState.Service.Connector.Name;
	}
	public Boolean getIsAuthorized() 
	{
		return ViewState.Authorized;
	}
	public Boolean getIsDirty() 
	{
		return ViewState.Dirty;
	}
	public Boolean getIsConfigured() 
	{
		return isConfigured();
	}
}
