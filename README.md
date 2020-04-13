# SCIM-Server-Powershell-Azure-Function
Scim 2.0 to Azure table on azure functions/powershell
PROJECT STATUS
==============
This project is in active development with the goal of completing basic protocol implementation by mid-2016.

Roadmap
-------
The list below doesn't necessarily denote priority or order.

- [ ] Finish users endpoints
  - [x] Create (post)
  - [X] Read (get)
    - [X] read all  
    - [X] read one  
    - [ ] search 
  - [ ] Replace (put)  
  - [ ] Update (Patch) (in progress - cleanup code)
    - [ ] Add  
    - [ ] Replace  
    - [ ] Remove  
  - [ ] Delete (delete)
  - [ ] Bulk (post)
- [x] Add SCIM server configuration endpoints
  - [x] /ServiceProviderConfig
  - [x] /Schemas
  - [x] /ResourceTypes
- [ ] Add support for mutability rule-processing.
- [ ] Add support for bulk processing
