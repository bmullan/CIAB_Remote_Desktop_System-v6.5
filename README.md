# CIAB_Remote_Desktop_System-v6.5

![ciab-logo](https://user-images.githubusercontent.com/1682855/51850975-ea4e3480-22f0-11e9-9128-d945e1e2a9ab.png?classes=float-left)  
  
##### (v6 March 2022)  
#### by Brian Mullan (bmullan.mail@gmail.com)  

---  

*Installation time is approx 15 minutes.*

---  

_**I am happy to introduce CIAB v6.5**_ of the CIAB Remote Desktop System.   I think you will really like the changes !   

With CIAB v6.5 the project *now has two **use-cases** supported* to enable *End-User* access to CIAB container Desktop Environments, Local or Remote:  

> **Use-Case (A)** - CLI direct access only to any of the *CIAB cCntainer Desktop Environments (DE)*  
> **Use-Case (B)** - Adds **HTML5 Browser HTTPS access using Guacamole, Tomcat, NGINX, PostgreSQL** *as a Web based Portal to Use-Case (A)*.

---

#### Steps to Install CIAB Use-Case (A)  

1) Create a temporary "work" directory on your server/VM/Cloud-Instance owner and group should be your UserID 
> **$ sudo mkdir /opt/ciab**  
> **$ sudo chown $USER:$USER /opt/ciab**    
> **$ sudo chmod 766 /opt/ciab**  
> **$ cd /opt/ciab/**  

2) Download the CIAB scripts from the Github Repository  
> **$ wget https://github.com/bmullan/CIAB_Remote_Desktop_System-v6.5/archive/refs/heads/main.zip**

3) **$ unzip unzip *.zip**  
4) now begin the process to create a CIAB LXD Desktop Container 
> **$ mk*.sh**  
> - This will execute the script "***mk-ciab-desktop-container.sh***".  

The User installing a CIAB Desktop Container will be asked for a name for the new Desktop Container.  

_During installation the CIAB Installer can choose from many different **Desktop Environments (DE)** including:_  
> - **KDE**  
> - **LXDE**  
> - **Budgie**  
> - **Gnome**  
> - **MATE**  
> - **XFCE**  
> - **KDE Plasma**   
> - **Cinnamon**  

CIAB installs each DE in a separate "unprivileged" LXD container whose name is entered by the CIAB Installer during installation.
For each DE selected & installed the CIAB Installing User will automatically be configuured with a User Account in that Desktop Container.

The CIAB Installer's Desktop container account will also be given "sudo" privileges in the Desktop container so they can provide adminstrative 
duties such as adding/removing applications/users. etc.  

> *NOTE: It may be useful to name the container with some indication of what Desktop Environment will be installed in it.*  

> ***Example***:   if the intent is to create a MATE Desktop Container... perhaps name the LXD Container "*mate-desktop*" etc.

Next the selected DE will be installed & configured in the Desktop Container.

The installation will also download source code for the very latest release of **[xRDP from NeutrinoLabs](https://github.com/neutrinolabs/xrdp)**  
The source code will be compiled w/support for Audio and Drive "redirection" enabled and then installed in the Desktop Container.

The last step the installation does is create a startup bash script with a highly customized xfreerdp command line *pre-built*
to connect via RDP to the associated Desktop Container's DE.   This created script will be placed in the installing UserID's
Host "Home" Directory and also copied to "/usr/bin/"

> **NOTE:**  *if the CIAB Container Desktop created was called **mate-desktop*** then the above "***startup bash scrip***t" would be  
> named "***mate-desktop.sh**"  

*At this point the selected Container Desktop Environment (DE) has been created and can be used from the CLI using the created startup Bash script !*

So *anyone with a User Account in that LXD Desktop Container (using our mate-desktop example)* would just execute:  
>  **$ mate-desktop.sh**  

*A login menu will pop-up and the user only needs to enter their Container Desktop Password which will bring up the Mate-Desktop in this example.*


---

#### Adding the Capability for End-Users to use an HTML5 Web Browser to access CIAB Desktop Containers

is a server application that integrates and extends the [Apache Guacamole](https://guacamole.apache.org/) clientless remote desktop gateway on a Ubuntu 20.04 LTS host with all applications running in LXD System Containers.   

_Using **only** a web browser that supports HTML5, users can connect to a **CIAB System installed either locally or remotely on Cloud, VM or Physical Server**._  

Earlier all of the CIAB installation files were copied to /opt/ciab/ so open a terminal and chancge to that directory:

> **$ cd /opt/ciab**  

Execute the script "***setup-ciab-guac.sh***"  which will:  
1) Create an additonal LXD container called "**ciab-guac**" and enable "*nesting*" *within the ciab-guac container*.  
2) Install a *Dockerized* *Guacamole, NGINX, Tomcat, PostgreSQL* container "***nested***" insude the LXD "ciab-guac" container.  

#### _**CIAB - "Cloud in a Box"**_  

The scripts/files in this repository _include all_ the installation Bash Scripts and associated files required to create *CIAB LXD container Desktop Systems*.  

We configure _Guacamole/NGINX_ etc with a _**"self-signed"**_ certificate to allow support for using HTTPS.   
  
This means the connection **from** a User **to** the Remote Desktop is _**encrypted**_.  

> _**NOTE**_ 
> ***With CIAB-Guacamole for user "Connections" you can configure CIAB-Guacamole to also connect to Windows Servers !***  


---
  
To configure the ***Guacamole*** front-end Proxy Follow the ***Installation Diagrams & Information*** in the   
_**[CIAB Remote Desktop System Installation Guide.PDF](https://github.com/bmullan/CIAB_Remote_Desktop_System-v6/blob/main/CIAB%20Remote%20Desktop%20System%20Installation.pdf)**_


---

---


