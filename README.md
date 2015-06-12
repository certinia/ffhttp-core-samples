OAuth Sample App
================

<a href="https://githubsfdeploy.herokuapp.com?owner=financialforcedev&repo=ffhttp-core-samples">
    <img alt="Deploy to Salesforce"
        src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/src/main/webapp/resources/img/deploy.png">
</a>

Summary
-------
This app has been built to demonstrate the use of the [Core](https://github.com/financialforcedev/ffhttp-core)  library. Specifically, it demonstrates how the library can be used to develop a VisualForce UI for the OAuth client.

Configuration
-------------

This section explains how to configure the OAuth Sample App.

1. Deploy the [Core](https://githubsfdeploy.herokuapp.com?owner=financialforcedev&repo=ffhttp-core) package to your Salesforce organisation.
2. Deploy the [OAuth Sample App](https://githubsfdeploy.herokuapp.com?owner=financialforcedev&repo=ffhttp-core-samples) to your organisation.
3. If the **OAuth Sample App** shows in the app menu then go to step 9.
4. Otherwise, go to **Setup** > **Manage Users** > **Users**.
5. Select your user.
6. Select **Edit Assignments** in the **Permission Set Assignments** section.
7. Add the **OAuth Sample App Permissions** permission set and **Save**.
8. The **OAuth Sample App** project should display in the app menu.
9. Select the **OAuth Sample App** project. The **Connector Types** and **Connectors** tabs should be displayed.

Creating a connection to another service
----------------------------------------
Once the app has been deployed you can then connect to another service. This section explains how to create a connection to Dropbox.

###Create an app in Dropbox

1. Create (or log in to) your Dropbox account.
2. Go to https://www.dropbox.com/developers/apps and select **Create App**.
3. Select **Dropbox API app** for **What type of data does your app need to store on Dropbox?**.
4. Select **Files and datastores** for **Can your app be limited to its own folder?**.
5. Select **No** as **Can your app be limited to its own folder?**.
6. Select **All file types** for **What type of files does your app need access to?**.
7. Enter an **App name** and select **Create App**.
8. Set the **Redirect URIs** to the URL of the Salesforce organisation e.g. https://eu3.salesforce.com/apex/connector.
9. Make sure you know the **App Key** and **App Secret** as they will be needed later.

###Create a Connector in Salesforce
1. Log in to your Salesforce organisation.
2. Select the **OAuth** app.
3. Select **Connector Types** then **New**.
4. Enter a **Connector Type Name** e.g. Dropbox.
5. Set the **Authorization Endpoint** to https://www.dropbox.com/1/oauth2/authorize.
6. Set the **Token Endpoint** to https://api.dropbox.com/1/oauth2/token.
7. Set the **Client ID** to the App Key obtained earlier.
8. Set the **Client Secret** to the App Secret obtained earlier.
9. Set the **Redirect URI** to the same URL as you set in step 8 in the Create an app in Dropbox section.
10. Set the **Developer Name** e.g. Dropbox 
10. Make sure that **Scope Required** is unchecked.
11. Set the **scope** to https://api.dropbox.com/.
12. **Save** the Connector Type.
13. Select **New Connector**.
14. Set the **Connector Name** and save.
15. Select the Connector and then **Activate**. You will be directed to another Salesforce page that activates your connector.
16. Select **Authorize**. This will prompt you to log in to your Google account (if you are not already logged in) and then authenticate the scope provided earlier. Select **Accept** to authorize.
17. Select **Save**. The connector is now ready for use.

Reporting Issues & Enhancements
-------------------------------

Please report any issues using the github [issues](https://github.com/financialforcedev/ffhttp-core-samples/issues) feature. Suggestions / bug reports are welcome as are extensions containing additional functionality.
