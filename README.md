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
