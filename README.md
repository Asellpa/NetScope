\# NetScope



> \*\*Know where the network breaks.\*\*



NetScope is an open-source Windows network diagnostics toolkit written in PowerShell.



It was created to answer a common troubleshooting question:



> \*\*Is the problem my PC, my router, my ISP, or the destination?\*\*



Instead of simply showing ping times, NetScope gathers diagnostic information that helps identify where connectivity problems begin.



\---



\## Features



Current features include:



\* Multi-target network monitoring

\* Packet loss tracking

\* Jitter calculation

\* Automatic network diagnosis

\* CSV logging

\* Event logging

\* Automatic traceroute capture on failures

\* HTML report generation

\* Live PowerShell dashboard



\---



\## Why NetScope?



Many existing tools show network statistics but leave the user to interpret them.



NetScope aims to explain those statistics by identifying likely causes of connectivity problems using diagnostic rules.



Examples include:



\* Local Ethernet or Wi-Fi issues

\* Router failures

\* ISP gateway outages

\* Upstream internet connectivity problems

\* Destination-specific issues



\---



\## Project Goals



NetScope is designed to become a complete Windows network diagnostics platform.



Planned features include:



\* Modular architecture

\* Automatic process discovery

\* Steam / Dota / Discord connection monitoring

\* ASN and provider identification

\* Historical latency graphs

\* Public IP monitoring

\* Intelligent diagnosis engine

\* Desktop application



\---



\## Getting Started



Clone the repository:



```powershell

git clone https://github.com/Asellpa/NetScope.git

```



Open PowerShell:



```powershell

cd NetScope

.\\NetScope.ps1

```



\---



\## Current Status



\*\*Version:\*\* 0.1.0 — Foundation



The project is under active development.



\---



\## License



Released under the MIT License.



