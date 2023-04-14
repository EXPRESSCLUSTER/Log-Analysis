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
3.	Click on **Add** and choose **Generate a script for a single server** to run on your target server.
4.	Review the **Prerequisites** page and click **Next**.
5.	On the **Resource** details tab:
    - Select your **Subscription**.
    - Select the appropriate **Resource Group**.
    - Select the appropriate **Region**.
    - Select the appropriate **Operating system**.
    - Select the appropriate **Connectivity method** (usually Public endpoint).
6.	Click **Next**.
7.	On the **Tags** tab:
    - Enter values for the **Physical location tags** (if desired), and any other custom tags as needed.
8.	Click **Next**.
9.	Click **Download** and review the script execution instructions.
10.	Click **Close**. 
11.	Copy the downloaded script to your target server.
12.	Open an elevated PowerShell windows on your server, change to the directory with the script, and run _**./OnboardingScript.ps1**_.
\*Note that you may need to change the execution policy in order to run the script. You will be prompted to enter your Azure credentials in order to connect to Azure. An Azure Arc-enabled resource will be created and associated with the agent.
13.	Verify that this succeeded by returning to the Azure portal and accessing the **Azure Arc – Servers** page. Your server should be listed with the status of _Connected_. Azure Monitor Agent should be installed as an extension of this Azure Arc server resource. The **Azure Connected Machine Agent** will have been installed on your on-premises server.

