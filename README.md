# K4 Config.xml Maker

A single page app to 
  - simplify the process of creating a K4 Config.xml file
  - illustrate the various components to new K4 Admins 
  - share configs with other admins

## Description

vjoon K4 client plug-in software relies on a `K4 Config.xml` file to provide it with
server and network details needed to establish communication with one or more K4 Servers.
This Single Page Application (SPA) displays a K4 Config.xml and allows users to modify it
by changing values on the web page.

## Getting Started

### Dependencies

* The SPA runs on most web browsers released after 2022.
* The SPA requires an internet conncetion to load JavaScript and CSS libraries.

### Installing

* The SPA is available for use [here](https://scottdunnflux.github.io/k4config-xml-maker/)
* Alternatively, the file may be downloaded and opened in a browser, however this will break the "Share" feature.

### Using the K4 Config.xml Maker

* Click the URL and specify one of the following:
  - make a new K4 Config.xml 
  - load one to be modified
  - generate one based on a K4 Server's test URL

* Clicking `New` will make a new K4 Config.xml with default values.
* Clicking `Load Config` will prompt you to load a K4 Config.xml file.
* Clicking `Apply Test URL` will prompt you to paste a URL to a K4 Server's test page. After pasting that URL into the space provided, click the `Apply Test URL` button to generate a `K4 Config.xml` that uses the protocol, address, port, and path shown in the test URL.

* Values may be modified in the Servers, InCopy Print Settings, and Proxy Settings sections. Changes will be reflected in the XML preview on the right side of the page.

* Once the settings have been specified the K4 Conig.xml maybe copied, downloaded, or shared by clicking the appropriate button.
* Read installation instructions and specify platform and versions to get a One-liner Install that can be pasted in to Terminal or CMD.

## Help

When in doubt, get a working test URL. This URL typically follows the format `https://k4.example.com:8443/K4Server/test/`. Once you've confirmed that the test URL works, use it with the Apply Test URL feature.

If your organization uses a proxy server, be sure to specify that here. 

## Authors

This SPA was developed by Scott Dunn at [Flux Consulting, Inc.](https://fluxconsulting.com) Contact [info@fluxconsulting.com](mailto:info@fluxconsulting.com) with questions or suggestions. And a lot of help from AI.

## Version History

* 2025-02-11
    * Inital version
* 2025-09-05
    * Optimized share URLs
    * Added One-liner Install feature
    * Now handles cases where admin URL is pasted instead of test URL

## License

This project is licensed under the MIT License - see the [LICENSE](License.md) file for details.

