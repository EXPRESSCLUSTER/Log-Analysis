# Azure Log Analytics with Azure Monitor Agent
This guide details how to set up an Azure Monitor Agent to collect ECX log files from on-premises Windows server nodes, monitor them for error events, and send email alerts when errors are detected. Note that since the legacy Log Analytics agent will be deprecated by August 2024, the Azure Monitor agent is used here. This guide details how to set this up for ECX VM nodes in an on-premises environment.    

In order to use Azure Monitor Agent to analyze ECX log files, you will first need an Azure account. Then you will need to create the following resources in Azure:
1. Resource Group
2. Log analytics workspace
3. Custom table
4. Data Collection Rule
     - Data collection endpoint
5. Alert Rule
     - action group

## 1. Resource Group
Log into the [Azure Portal](https://portal.azure.com/) and create a **Resource Group** for *Azure log analytics*.
1.	Search for and select **Resource groups**.
2.	Click **Create**.
    - Select your **Subscription**'
    - Enter a unique name for your **Resource group**'
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



## On-premises server prep
Azure Arc needs to be enabled in the on-premises server in order to send log files to Azure monitor. You will need to deploy and configure the Azure Connected Machine agent on your server.
