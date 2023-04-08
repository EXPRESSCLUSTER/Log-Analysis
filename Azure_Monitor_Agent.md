# Azure Log Analytics with Azure Monitor Agent
This guide details how to set up an Azure Monitor Agent to collect ECX log files from on-premises Windows server nodes, monitor them for error events, and send email alerts when errors are detected.    

In order to use Azure Monitor Agent to analyze ECX log files, you will first need an Azure account. Then you will need to create the following resources in Azure:
1. Resource Group
2. Log analytics workspace
3. Custom table
4. Data Collection Rule
     - Data collection endpoint
5. Alert Rule
     - action group

## On-premises server prep
Azure Arc needs to be enabled in the on-premises server in order to send log files to Azure monitor. You will need to deploy and configure the Azure Connected Machine agent on your server.
