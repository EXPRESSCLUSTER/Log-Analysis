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
12.	Click Add data source.
13.	Pull down the drop box under Data source type to reveal the options available.
14.	Select Custom Text Logs.
*Note that if no data collection endpoint was selected earlier, this option will be unavailable.
15.	Enter the following in the Data source window:
- File pattern: C:\Program Files\EXPRESSCLUSTER\log\userlog*.log
- Table name: <table name created previously – don’t forget the _CL at the end>
- Transform: leave as source
16.	Click Next : Destination.
17.	Verify that the Destination type is Azure Monitor Logs, your Subscription is selected, and the Account or namespace is set to your Log Analytics workspace.
18.	Click Add data source.
The Data source should have Custom Text Logs and the Destination(s) should show Azure Monitor Logs.
19.	Click Next : Review + Create.
20.	If everything looks good, click Create.
21.	Click on Go to resource to view the newly created resource.




