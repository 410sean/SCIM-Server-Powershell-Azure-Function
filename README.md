# SCIM-Server-Powershell-Azure-Function
Scim 2.0 to Azure table on azure functions/powershell

GETTING STARTED
==============
1) in portal.azure.com create a new function app. choose code and powershell core
2) once created open the storage account used for the function app and create a table "scimConfig"
3) populate table using scomConfig.csv and skip to step 9 or manually enter the following
4) optional PartitionKey = ServiceProviderConfig;RowKey = ;json = {what you want returned}
5) optional PartitionKey = Schema;RowKey = urn:ietf:params:scim:schemas:core:2.0:User ;json = {what you want returned}
6) optional PartitionKey = ResourceType;RowKey = User;json = {what you want returned}
7) optional repeat as needed for each attribute. PartitionKey = urn:ietf:params:scim:schemas:core:2.0:User; RowKey = {attribute name}; json = {what you want the attributeschema for this to look like}
8) optional for rest populated attributes follow 7 but also add the pollowing properties. input = {json schema of input body}; url = {post url of api}; output = {json schema of expected response}
9)create table 'User'
10) on the app service go to configuration, ensure you have an application setting for AzureWebJobsStorage and create one called basicauth with the value enabled=true;client_id={username};client_secret={password}
11) clone this repo using github desktop or downloading as a zip to your machine and using vs code with azure functions extension open this repo
12) on the left side click azure, expand functions, the subscription you created a function app, and right click the appropriate function and choose "Deploy to Function App..."





PROJECT STATUS
==============
This project is in active development with the goal of completing basic protocol implementation by mid-2016.

Roadmap
-------
The list below doesn't necessarily denote priority or order.

- [ ] Finish users endpoints
  - [x] Create (post)
    - [X] check required
    - [ ] check uniqueness
    - [x] add rest attributes
  - [X] Read (get)
    - [X] read all  
    - [X] read one  
    - [ ] search 
  - [ ] Replace (put)  
  - [ ] Update (Patch)
    - [ ] Add  
    - [ ] Replace  
    - [ ] Remove  
  - [ ] Delete (delete)
  - [ ] Bulk (post)
- [x] Add SCIM server configuration endpoints
  - [x] /ServiceProviderConfig
  - [x] /Schemas
  - [x] /ResourceTypes
- [ ] Add support for Rest attributes
  - [ ] parse input/output schema
