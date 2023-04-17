# Azure Log Analytics with Azure Monitor Agent
This guide details how to set up an Azure Monitor Agent to collect ECX log files from on-premises Windows server nodes, monitor them for error events, and send email alerts when errors are detected. Note that since the legacy Log Analytics agent will be deprecated by August 2024, the Azure Monitor agent is used here. This guide details how to set this up for ECX VM nodes in an on-premises environment.    

In order to use Azure Monitor Agent to analyze ECX log files, you will first need an Azure account. Then you will need to create the following resources in Azure:
1. Resource Group
2. Log analytics workspace
3. On-premises server prep (download script to run on the VM)
4. Custom table
5. Data Collection Rule
     - Data collection endpoint
6. Alert Rule
     - action group

## 1. Resource Group
Log into the [Azure Portal](https://portal.azure.com/) and create a **Resource Group** for *Azure log analytics*.
1.	Search for and select **Resource groups**.
2.	Click **Create**.
    - Select your **Subscription**.
    - Enter a unique name for your **Resource group**.
    - Choose the appropriate **Region** to used for all of the resources to be created.
3.	Click **Review + Create**.
4.	Click **Create**.

\*Note - you will use this resource group for all of the resources created for this project.

## 2. Log Analytics workspace
1.	Search for **Log Analytics workspaces** in the Azure Portal.   
2.	Click **Create**.
3.	Choose your **Subscription** and the **Resource Group** just created. Enter a unique **Name** and appropriate **Region**. Add **Tags** if needed.
4.	Click **Review + Create**.
5.	Click **Create**.

## 4. On-premises server prep

Azure Arc needs to be enabled in the on-premises server in order to send log files to Azure monitor. You will need to deploy and configure the **Azure Connected Machine agent** on your server. The simplest way to do this is to download a script to automate this process. This script will also download and install the **connected machine agent** and then connect to **Azure Arc**.    

1.	Log into the [Azure Portal](https://portal.azure.com/).
2.	Search for and select **Servers – Azure Arc**.
3.	Click on **Add** and choose **Generate script** (for a single server) to run on your target server.    
     ![Generate Script](images/Installed%20Generate%20Script.png)
5.	Review the **Prerequisites** page and click **Next**.
6.	On the **Resource** details tab:
    - Select your **Subscription**.
    - Select the appropriate **Resource Group**.
    - Select the appropriate **Region**.
    - Select the appropriate **Operating system**.
    - Select the appropriate **Connectivity method** (usually Public endpoint).
7.	Click **Next**.
8.	On the **Tags** tab:
    - Enter values for the **Physical location tags** (if desired), and any other custom tags as needed.
9.	Click **Next**.
10.	Click **Download** and review the script execution instructions.
11.	Click **Close**. 
12.	Copy the downloaded script to your target server.
13.	Open an elevated PowerShell windows on your server, change to the directory with the script, and run _**./OnboardingScript.ps1**_.    
\*Note that you may need to change the execution policy in order to run the script. The script will prompt you to enter your Azure credentials in order to connect to Azure. An Azure Arc-enabled resource will be created for your server and associated with the agent.
13.	Verify that this succeeded by returning to the Azure portal and accessing the **Azure Arc – Servers** page. Your server should be listed with the status of _Connected_. Azure Monitor Agent should be installed as an extension of this Azure Arc server resource. The **Azure Connected Machine Agent** will have been installed on your on-premises server.    
![Azure Arc Server](images/Installed%20Azure%20Arc%20Server.png)    

## 4. Custom table
A custom table needs to be created in the Log Analytics workspace for the log data which will be collected. The Data Collection Rule, which will be created later, will channel log file data to this table.
1.	Copy the code below and change the parameters in the braces to match your Azure environment. This code can be modified to add other columns if needed. Be sure not to add any extra spaces anywhere in the script. You will choose your own TableName (replace the place holder in two places in the script).

```
    $tableParams = @'
    {
       "properties": {
           "schema": {
                  "name": "{TableName}_CL",
                  "columns": [
           {
                                   "name": "TimeGenerated",
                                   "type": "DateTime"
                           }, 
                          {
                                   "name": "RawData",
                                   "type": "String"
                          }
                 ]
           }
       }
    }
    '@

    Invoke-AzRestMethod -Path "/subscriptions/{subscription}/resourcegroups/{resourcegroup}/providers/microsoft.operationalinsights/workspaces/{WorkspaceName}/tables/{TableName}_CL?api-version=2021-12-01-preview" -Method PUT -payload $tableParams
```    
2.	It is easiest to create this table from an **Azure Cloud PowerShell** command line in Azure. From the Azure portal press the **Cloud Shell** button int the top right bar. Then select **PowerShell**. Copy and paste the script and press return to execute the script.
3.	To verify that the table was made, return to your **Log Analytics workspace** in Azure and click on the **Tables** blade under **Settings**.    
\*Note that this script and instructions were found at the following [Microsoft learn link](https://learn.microsoft.com/en-us/azure/azure-monitor/agents/data-collection-text-log?tabs=portal).    
![Log Analytics Workspace Table](images/Installed%20Tables.png)

## 5. Data Collection Rule
A Data Collection Rule will define the data collection process in Azure Monitor. It specifies what will be collected, where to send the data, and how it will be transformed. The instructions for the following rule will collect ECX custom logs from on-premises ECX servers.
1.	Search for **Monitor** in the Azure portal to access the **Monitor** menu.
2.	Click on **Data Collection Rules** in the left blade under **Settings**.
3.	Select **Create**.
4.	On the **Basics** tab:
    - Enter a unique **Rule Name** for this rule.
    - Select your **Subscription**.
    - Select the **Resource Group** created earlier.
    - Delect the correct **Region**.
    - Select the **Platform Type** (Windows or Linux).    
  \*Note - A Data Collection Endpoint will be created later. Click **Next : Resources**.
5.	On the **Resources** tab, click **Add resources**.
![DCR Resources](images/Installed%20DCR%20Resources.png)
6.	Expand your resource group to show the Azure Arc enabled servers. Check the boxes next to the servers to include in the scope and click **Apply**.
7.	Click **Create endpoint**.    
    \*Note that an endpoint is needed for Custom Text Logs. 
    - enter a unique Endpoint Name
    - select your Subscription
    - select the Resource Group created earlier
    - select the same Region as used previously    
    Click **Review + Create**. Click **Create**.
8.	Check the box next to **Enable Data Collection Endpoints** to show the **Data Collection Endpoint Column** in the lower table.
9.	Select the **Data collection endpoint** just created in the new column for each server.
10.	Return to the **Basics** tab and select the **Data Collection Endpoint** just created.
11.	Click **Next : Resources** and then **Next : Collect and deliver** to continue.
12.	Click **Add data source**.
13.	Pull down the drop box under **Data source type** to reveal the options available.
![Data Source Type](images/Installed%20Data%20Source%20Type.png)
14.	Select **Custom Text Logs**.    
*Note that if no data collection endpoint was created and selected earlier, this option will not be available.
15.	Enter the following in the Data source window:
    - **File pattern**: _C:\Program Files\EXPRESSCLUSTER\log\userlog*.log_.
    - **Table name**: \<_table name created previously_ – don’t forget the *_CL* at the end\>.
    - **Transform**: leave as _source_.
16.	Click **Next : Destination**.
17.	Confirm the following:
    - **Destination type**: Azure Monitor Logs.
    - **Subscription** is correct.
    - **Account or namespace** is set to your **Log Analytics workspace**.
18.	Click **Add data source**.    
The **Data source** column should have **Custom Text Logs** and the **Destination(s)** should show **Azure Monitor Logs**.
19.	Click **Next : Review + Create**.
20.	If everything looks good, click **Create**.
21.	Click on **Go to resource** to view the newly created resource.

## Verify that the text logs are being populated
1.	Open the Azure ** Monitor** page.
2.	Click on **Logs** in the left blade.
3.	Close the **Queries** popup window.
4.	Click **Select scope** in the upper left, expand your **Resource group**, select your **Log Analytics workspace**, and click **Apply**.
![Select a Scope](images/Installed%20Select%20a%20scope.png)
5.	Enter the name of your custom log file in the query window. You can expand the **Custom Logs** list if you need help remembering it. Click **Run**.
6.	If you have given the system enough time to collect logs and nothing is displayed for the default **Last 24 hours** period, change the **Time range** to a longer period and try again.    
\*Note that all of the log entries collected over that time period will display, including “INFO” events.
 ![Basic Log Query](images/Azure%20Monitor%20Basic%20Log%20Query.png)
7.	Enter the following query to view organized error events:
```
<log_name>_CL
| where RawData contains "ERROR"
| order by TimeGenerated asc 
| project TimeGenerated, ComputerName=tostring(split(_ResourceId, "/")[-1]), RawData
```
![Query for ERROR](images/Azure%20Monitor%20Log%20Query%20for%20ERROR.png)
\*Note that changing _contains_ to _contains_cs_ will perform a case sensitive query.

## Alert Rule
Once Azure starts collecting ECX logs, it is possible to create an Alert Rule to notify the ECX administrator when error messages are logged.
1.	Search for **Monitor** in the Azure portal to access the **Monitor** menu.
2.	Click on **Alerts** in the left blade.
3.	Click **Create -> Alert rule**.
4.	At the **Scope** tab a window called **Select a resource** should automatically pop up. Expand your **Resource group** and put a check next to your **Log Analytics workspace**. Click **Apply**.
![Select a Resource](images/Installed%20Select%20a%20resource.png)
5.	Click **Next : Conditions**.
6.	Set the following for the Condition tab:
    - Signal name: Custom log search    
      *Note that this will expand more options
    - Search query: 
    ```
    <table name_CL> 
    | where RawData contains "ERROR"
    ```   
    ![Alert Log Query](images/Installed%20Alert%20Log%20Query.png)
    \*Note that you can test this query. If it does not return any results, adjust the **Time range**. Click **Continue Editing Alert** to close this window.
- Measurement: leave Measure set to Table rows, Aggregation type set to Count, and Aggregation granularity set to 5 minutes.
- Split by dimensions 
    - Resource ID column: leave set to _ResourceId.
- Alert logic
    - Operator: Greater than
    - Threshold value: 0
    - Frequency of evaluation: 5 minutes
Leave the other settings as default values and click Next : Actions.
7.	Click Create action group under the Actions tab.
*Note that the action group tells Azure what to do when an alert is received.
8.	Enter the following values on the Basics tab:
- select your Subscription
- select the appropriate Resource Group
- select the appropriate Region
- enter a unique name for the Action group name
- the Display name will show up in notifications. Change it if you like.
9.	Click Next : Notifications.
10.	Choose the following on the Notifications tab:
- Notification type: Email/SMS message/Push/Voice
- Name: a name of your choice
*Note - If a popup window did not appear for to allow you to ‘Add or edit Email/SMS message/Push/Voice action’, click on the pencil icon.
- Check the box next to Email and enter the email address to receive notification.
- Select Yes to enable the common alert schema and click OK.
11.	Click Next : Actions.
12.	The settings on the Actions tab do not need to be modified. They may be used for more advanced actions if needed such as web hooks Azure functions Logic Apps.
13.	Click Next : Tags and add any tags as needed.
14.	Click Next : Review + Create.
15.	If everything looks good, click Create.
The action group just created should be listed under Action group name.
16.	Click Next : Details.
17.	On the Details tab, modify the following as needed:
- select your Subscription
- select the appropriate Resource Group
- Severity: 1 – Error
- Alert rule name: a name of your choice
- Alert rule description: description is optional
- select the appropriate Region
- Advanced options -> Custom properties (if desired)
18.	Click Next : Tags.
19.	Add any tag values and click Next : Review + create.
20.	Click Create.
The new rule will show in the list of alert rules and be enabled.
*Note that the Monitor – Alerts page shows the alerts that have been fired within the selected time frame. Click Alert rules to view and edit alert rules.




