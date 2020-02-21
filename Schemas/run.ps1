using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Interact with query parameters or the body of the request.
$name = $Request.Query.Name
if (-not $name) {
    $name = $Request.Body.Name
}

if ($name) {
    $status = [HttpStatusCode]::OK
    $body = "Hello $name"
}
else {
    $status = [HttpStatusCode]::BadRequest
    $body = "Please pass a name on the query string or in the request body."
}
$status = [HttpStatusCode]::OK
$body='{
  "totalResults": 1,
  "itemsPerPage": 100,
  "startIndex": 1,
  "schemas": [
    "urn:ietf:params:scim:api:messages:2.0:ListResponse"
  ],
  "Resources": [
    {
      "id": "urn:ietf:params:scim:schemas:core:2.0:User",
      "name": "User",
      "description": "Front teammate Account",
      "attributes": [
        {
          "name": "userName",
          "description": "Teammate''s alias. REQUIRED.",
          "type": "string",
          "multiValued": false,
          "required": true,
          "caseExact": false,
          "mutability": "readWrite",
          "returned": "default",
          "uniqueness": "server"
        },
        {
          "name": "name",
          "description": "The components of the teammate''s real name. REQUIRED",
          "type": "complex",
          "multiValued": false,
          "required": true,
          "mutability": "readWrite",
          "returned": "default",
          "uniqueness": "none",
          "subAttributes": [
            {
              "name": "formatted",
              "description": "The full name, including all middle names, titles, and suffixes as appropriate. UNSUPPORTED",
              "type": "string",
              "multiValued": false,
              "required": false,
              "caseExact": false,
              "mutability": "readWrite",
              "returned": "default",
              "uniqueness": "none"
            },
            {
              "name": "familyName",
              "description": "The family name of the Teammate, or last name in most Western languages. REQUIRED",
              "type": "string",
              "multiValued": false,
              "required": true,
              "caseExact": false,
              "mutability": "readWrite",
              "returned": "default",
              "uniqueness": "none"
            },
            {
              "name": "givenName",
              "description": "The given name of the Teammate, or first name in most Western languages. REQUIRED",
              "type": "string",
              "multiValued": false,
              "required": true,
              "caseExact": false,
              "mutability": "readWrite",
              "returned": "default",
              "uniqueness": "none"
            },
            {
              "name": "middleName",
              "description": "The middle name(s) of the Teammate. UNSUPPORTED",
              "type": "string",
              "multiValued": false,
              "required": false,
              "caseExact": false,
              "mutability": "readWrite",
              "returned": "default",
              "uniqueness": "none"
            },
            {
              "name": "honorificPrefix",
              "description": "The honorific prefix(es) of the Teammate, or title in most Western languages. UNSUPPORTED",
              "type": "string",
              "multiValued": false,
              "required": false,
              "caseExact": false,
              "mutability": "readWrite",
              "returned": "default",
              "uniqueness": "none"
            },
            {
              "name": "honorificSuffix",
              "description": "The honorific suffix(es) of the Teammate, or suffix in most Western languages. UNSUPPORTED",
              "type": "string",
              "multiValued": false,
              "required": false,
              "caseExact": false,
              "mutability": "readWrite",
              "returned": "default",
              "uniqueness": "none"
            }
          ]
        },
        {
          "name": "displayName",
          "description": "The name of the Teammate, suitable for display to end-users. UNSUPPORTED",
          "type": "string",
          "multiValued": false,
          "required": false,
          "caseExact": false,
          "mutability": "readWrite",
          "returned": "default",
          "uniqueness": "none"
        },
        {
          "name": "nickName",
          "description": "The casual way to address the teammate in real life. UNSUPPORTED",
          "type": "string",
          "multiValued": false,
          "required": false,
          "caseExact": false,
          "mutability": "readWrite",
          "returned": "default",
          "uniqueness": "none"
        },
        {
          "name": "profileUrl",
          "description": "A fully qualified URL pointing to a page representing the Teammate''s online profile. UNSUPPORTED",
          "type": "reference",
          "referenceTypes": [
            "external"
          ],
          "multiValued": false,
          "required": false,
          "caseExact": false,
          "mutability": "readWrite",
          "returned": "default",
          "uniqueness": "none"
        },
        {
          "name": "title",
          "description": "The user''s title, such as ''Vice President.'' UNSUPPORTED",
          "type": "string",
          "multiValued": false,
          "required": false,
          "caseExact": false,
          "mutability": "readWrite",
          "returned": "default",
          "uniqueness": "none"
        },
        {
          "name": "userType",
          "description": "Used to identify the relationship between the organization and the teammate. UNSUPPORTED",
          "type": "string",
          "multiValued": false,
          "required": false,
          "caseExact": false,
          "mutability": "readWrite",
          "returned": "default",
          "uniqueness": "none"
        },
        {
          "name": "preferredLanguage",
          "description": "Indicates the Teammate''s preferred written or spoken language. UNSUPPORTED",
          "type": "string",
          "multiValued": false,
          "required": false,
          "caseExact": false,
          "mutability": "readWrite",
          "returned": "default",
          "uniqueness": "none"
        },
        {
          "name": "locale",
          "description": "Used to indicate the Teammate''s default location for purposes of localizing items such as currency, date time format, or numerical representations. UNSUPPORTED",
          "type": "string",
          "multiValued": false,
          "required": false,
          "caseExact": false,
          "mutability": "readWrite",
          "returned": "default",
          "uniqueness": "none"
        },
        {
          "name": "timezone",
          "description": "The Teammate''s time zone in the ''Olson'' time zone database format, e.g., ''America/Los_Angeles''. UNSUPPORTED",
          "type": "string",
          "multiValued": false,
          "required": false,
          "caseExact": false,
          "mutability": "readWrite",
          "returned": "default",
          "uniqueness": "none"
        },
        {
          "name": "active",
          "description": "A Boolean value indicating the Teammate''s administrative status. (Default to true)",
          "type": "boolean",
          "multiValued": false,
          "required": false,
          "mutability": "readWrite",
          "returned": "default"
        },
        {
          "name": "password",
          "description": "The Teammate''s cleartext password. (Default to a random string)",
          "type": "string",
          "multiValued": false,
          "required": false,
          "caseExact": false,
          "mutability": "writeOnly",
          "returned": "never",
          "uniqueness": "none"
        },
        {
          "name": "emails",
          "description": "Email addresses for the teammate. (Support only primary)",
          "type": "complex",
          "multiValued": true,
          "required": false,
          "mutability": "readWrite",
          "returned": "default",
          "uniqueness": "none",
          "subAttributes": [
            {
              "name": "value",
              "description": "Email addresses for the teammate.",
              "type": "string",
              "multiValued": false,
              "required": false,
              "caseExact": false,
              "mutability": "readWrite",
              "returned": "default",
              "uniqueness": "none"
            },
            {
              "name": "display",
              "description": "A human-readable name, primarily used for display purposes. UNSUPPORTED",
              "type": "string",
              "multiValued": false,
              "required": false,
              "caseExact": false,
              "mutability": "readWrite",
              "returned": "default",
              "uniqueness": "none"
            },
            {
              "name": "type",
              "description": "A label indicating the email''s function. UNSUPPORTED",
              "type": "string",
              "multiValued": false,
              "required": false,
              "caseExact": false,
              "canonicalValues": [
                "work",
                "home",
                "other"
              ],
              "mutability": "readWrite",
              "returned": "default",
              "uniqueness": "none"
            },
            {
              "name": "primary",
              "description": "A Boolean value indicating the email to use for the teammate. The primary attribute value true MUST appear no more than once.",
              "type": "boolean",
              "multiValued": false,
              "required": false,
              "mutability": "readWrite",
              "returned": "default"
            }
          ]
        },
        {
          "name": "phoneNumbers",
          "description": "Phone numbers for the Teammate. UNSUPPORTED",
          "type": "complex",
          "multiValued": true,
          "required": false,
          "mutability": "readWrite",
          "returned": "default",
          "subAttributes": [
            {
              "name": "value",
              "description": "Phone number of the Teammate. UNSUPPORTED",
              "type": "string",
              "multiValued": false,
              "required": false,
              "caseExact": false,
              "mutability": "readWrite",
              "returned": "default",
              "uniqueness": "none"
            },
            {
              "name": "display",
              "description": "A human-readable name, primarily used for display purposes. UNSUPPORTED",
              "type": "string",
              "multiValued": false,
              "required": false,
              "caseExact": false,
              "mutability": "readWrite",
              "returned": "default",
              "uniqueness": "none"
            },
            {
              "name": "type",
              "description": "A label indicating the phone number''s function. UNSUPPORTED",
              "type": "string",
              "multiValued": false,
              "required": false,
              "caseExact": false,
              "canonicalValues": [
                "work",
                "home",
                "mobile",
                "fax",
                "pager",
                "other"
              ],
              "mutability": "readWrite",
              "returned": "default",
              "uniqueness": "none"
            },
            {
              "name": "primary",
              "description": "A Boolean value indicating the preferred attribute value for this attribute. UNSUPPORTED",
              "type": "boolean",
              "multiValued": false,
              "required": false,
              "mutability": "readWrite",
              "returned": "default"
            }
          ]
        },
        {
          "name": "ims",
          "description": "Instant messaging addresses for the Teammate. UNSUPPORTED",
          "type": "complex",
          "multiValued": true,
          "required": false,
          "mutability": "readWrite",
          "returned": "default",
          "subAttributes": [
            {
              "name": "value",
              "description": "Instant messaging address for the Teammate. UNSUPPORTED",
              "type": "string",
              "multiValued": false,
              "required": false,
              "caseExact": false,
              "mutability": "readWrite",
              "returned": "default",
              "uniqueness": "none"
            },
            {
              "name": "display",
              "description": "A human-readable name, primarily used for display purposes. UNSUPPORTED",
              "type": "string",
              "multiValued": false,
              "required": false,
              "caseExact": false,
              "mutability": "readWrite",
              "returned": "default",
              "uniqueness": "none"
            },
            {
              "name": "type",
              "description": "A label indicating the instant messaging''s function. UNSUPPORTED",
              "type": "string",
              "multiValued": false,
              "required": false,
              "caseExact": false,
              "canonicalValues": [
                "aim",
                "gtalk",
                "icq",
                "xmpp",
                "msn",
                "skype",
                "qq",
                "wechat",
                "yahoo"
              ],
              "mutability": "readWrite",
              "returned": "default",
              "uniqueness": "none"
            },
            {
              "name": "primary",
              "description": "A Boolean value indicating the ''primary'' or preferred attribute value for this attribute, e.g., the preferred messenger or primary messenger.  The primary attribute value ''true'' MUST appear no more than once. UNSUPPORTED",
              "type": "boolean",
              "multiValued": false,
              "required": false,
              "mutability": "readWrite",
              "returned": "default"
            }
          ]
        },
        {
          "name": "photos",
          "description": "URLs of photos of the Teammate. UNSUPPORTED",
          "type": "complex",
          "multiValued": true,
          "required": false,
          "mutability": "readWrite",
          "returned": "default",
          "subAttributes": [
            {
              "name": "value",
              "description": "URL of a photo of the Teammate. UNSUPPORTED",
              "type": "reference",
              "referenceTypes": [
                "external"
              ],
              "multiValued": false,
              "required": false,
              "caseExact": false,
              "mutability": "readWrite",
              "returned": "default",
              "uniqueness": "none"
            },
            {
              "name": "display",
              "description": "A human-readable name, primarily used for display purposes. UNSUPPORTED",
              "type": "string",
              "multiValued": false,
              "required": false,
              "caseExact": false,
              "mutability": "readWrite",
              "returned": "default",
              "uniqueness": "none"
            },
            {
              "name": "type",
              "description": "A label indicating the photo''s function. UNSUPPORTED",
              "type": "string",
              "multiValued": false,
              "required": false,
              "caseExact": false,
              "canonicalValues": [
                "photo",
                "thumbnail"
              ],
              "mutability": "readWrite",
              "returned": "default",
              "uniqueness": "none"
            },
            {
              "name": "primary",
              "description": "A Boolean value indicating the ''primary'' or preferred attribute value for this attribute, e.g., the preferred photo or thumbnail.  The primary attribute value ''true'' MUST appear no more than once. UNSUPPORTED",
              "type": "boolean",
              "multiValued": false,
              "required": false,
              "mutability": "readWrite",
              "returned": "default"
            }
          ]
        },
        {
          "name": "addresses",
          "description": "A physical mailing address for this Teammate. UNSUPPORTED.",
          "type": "complex",
          "multiValued": true,
          "required": false,
          "mutability": "readWrite",
          "returned": "default",
          "uniqueness": "none",
          "subAttributes": [
            {
              "name": "formatted",
              "description": "The full mailing address, formatted for display or use with a mailing label. UNSUPPORTED",
              "type": "string",
              "multiValued": false,
              "required": false,
              "caseExact": false,
              "mutability": "readWrite",
              "returned": "default",
              "uniqueness": "none"
            },
            {
              "name": "streetAddress",
              "description": "The full street address component, which may include house number, street name, P.O. box, and multi-line extended street address information. UNSUPPORTED",
              "type": "string",
              "multiValued": false,
              "required": false,
              "caseExact": false,
              "mutability": "readWrite",
              "returned": "default",
              "uniqueness": "none"
            },
            {
              "name": "locality",
              "description": "The city or locality component. UNSUPPORTED",
              "type": "string",
              "multiValued": false,
              "required": false,
              "caseExact": false,
              "mutability": "readWrite",
              "returned": "default",
              "uniqueness": "none"
            },
            {
              "name": "region",
              "description": "The state or region component. UNSUPPORTED",
              "type": "string",
              "multiValued": false,
              "required": false,
              "caseExact": false,
              "mutability": "readWrite",
              "returned": "default",
              "uniqueness": "none"
            },
            {
              "name": "postalCode",
              "description": "The zip code or postal code component. UNSUPPORTED",
              "type": "string",
              "multiValued": false,
              "required": false,
              "caseExact": false,
              "mutability": "readWrite",
              "returned": "default",
              "uniqueness": "none"
            },
            {
              "name": "country",
              "description": "The country name component. UNSUPPORTED",
              "type": "string",
              "multiValued": false,
              "required": false,
              "caseExact": false,
              "mutability": "readWrite",
              "returned": "default",
              "uniqueness": "none"
            },
            {
              "name": "type",
              "description": "A label indicating the address'' function. UNSUPPORTED",
              "type": "string",
              "multiValued": false,
              "required": false,
              "caseExact": false,
              "canonicalValues": [
                "work",
                "home",
                "other"
              ],
              "mutability": "readWrite",
              "returned": "default",
              "uniqueness": "none"
            },
            {
              "name": "primary",
              "description": "A Boolean value indicating the preferred attribute value for this attribute. UNSUPPORTED",
              "type": "boolean",
              "multiValued": false,
              "required": false,
              "mutability": "readWrite",
              "returned": "default"
            }
          ]
        },
        {
          "name": "groups",
          "description": "A list of groups to which the teammate belongs, either through direct membership, through nested groups, or dynamically calculated. UNSUPPORTED",
          "type": "complex",
          "multiValued": true,
          "required": false,
          "mutability": "readOnly",
          "returned": "default",
          "subAttributes": [
            {
              "name": "value",
              "description": "The identifier of the Teammate''s group. UNSUPPORTED",
              "type": "string",
              "multiValued": false,
              "required": false,
              "caseExact": false,
              "mutability": "readOnly",
              "returned": "default",
              "uniqueness": "none"
            },
            {
              "name": "$ref",
              "description": "The URI of the corresponding ''Group'' resource to which the teammate belongs. UNSUPPORTED",
              "type": "reference",
              "referenceTypes": [
                "User",
                "Group"
              ],
              "multiValued": false,
              "required": false,
              "caseExact": false,
              "mutability": "readOnly",
              "returned": "default",
              "uniqueness": "none"
            },
            {
              "name": "display",
              "description": "A human-readable name, primarily used for display purposes. UNSUPPORTED",
              "type": "string",
              "multiValued": false,
              "required": false,
              "caseExact": false,
              "mutability": "readOnly",
              "returned": "default",
              "uniqueness": "none"
            },
            {
              "name": "type",
              "description": "A label indicating the group''s function. UNSUPPORTED",
              "type": "string",
              "multiValued": false,
              "required": false,
              "caseExact": false,
              "canonicalValues": [
                "direct",
                "indirect"
              ],
              "mutability": "readOnly",
              "returned": "default",
              "uniqueness": "none"
            }
          ]
        },
        {
          "name": "entitlements",
          "description": "A list of entitlements for the Teammate that represent a thing the Teammate has. UNSUPPORTED",
          "type": "complex",
          "multiValued": true,
          "required": false,
          "mutability": "readWrite",
          "returned": "default",
          "subAttributes": [
            {
              "name": "value",
              "description": "The value of an entitlement. UNSUPPORTED",
              "type": "string",
              "multiValued": false,
              "required": false,
              "caseExact": false,
              "mutability": "readWrite",
              "returned": "default",
              "uniqueness": "none"
            },
            {
              "name": "display",
              "description": "A human-readable name, primarily used for display purposes. UNSUPPORTED",
              "type": "string",
              "multiValued": false,
              "required": false,
              "caseExact": false,
              "mutability": "readWrite",
              "returned": "default",
              "uniqueness": "none"
            },
            {
              "name": "type",
              "description": "A label indicating the entitlement''s function. UNSUPPORTED",
              "type": "string",
              "multiValued": false,
              "required": false,
              "caseExact": false,
              "mutability": "readWrite",
              "returned": "default",
              "uniqueness": "none"
            },
            {
              "name": "primary",
              "description": "A Boolean value indicating the preferred attribute value for this attribute. UNSUPPORTED",
              "type": "boolean",
              "multiValued": false,
              "required": false,
              "mutability": "readWrite",
              "returned": "default"
            }
          ]
        },
        {
          "name": "roles",
          "description": "A list of roles for the Teammate that collectively represent who the Teammate.",
          "type": "complex",
          "multiValued": true,
          "required": false,
          "mutability": "readWrite",
          "returned": "default",
          "subAttributes": [
            {
              "name": "value",
              "description": "The value of a role.",
              "type": "string",
              "multiValued": false,
              "required": false,
              "caseExact": false,
              "mutability": "readWrite",
              "returned": "default",
              "uniqueness": "none"
            },
            {
              "name": "display",
              "description": "A human-readable name, primarily used for display purposes. UNSUPPORTED",
              "type": "string",
              "multiValued": false,
              "required": false,
              "caseExact": false,
              "mutability": "readWrite",
              "returned": "default",
              "uniqueness": "none"
            },
            {
              "name": "type",
              "description": "A label indicating the role''s function. UNSUPPORTED",
              "type": "string",
              "multiValued": false,
              "required": false,
              "caseExact": false,
              "canonicalValues": [],
              "mutability": "readWrite",
              "returned": "default",
              "uniqueness": "none"
            },
            {
              "name": "primary",
              "description": "A Boolean value indicating the preferred attribute value for this attribute. UNSUPPORTED",
              "type": "boolean",
              "multiValued": false,
              "required": false,
              "mutability": "readWrite",
              "returned": "default"
            }
          ]
        },
        {
          "name": "x509Certificates",
          "description": "A list of certificates issued to the Teammate. UNSUPPORTED",
          "type": "complex",
          "multiValued": true,
          "required": false,
          "caseExact": false,
          "mutability": "readWrite",
          "returned": "default",
          "subAttributes": [
            {
              "name": "value",
              "description": "The value of an X.509 certificate. UNSUPPORTED",
              "type": "binary",
              "multiValued": false,
              "required": false,
              "caseExact": false,
              "mutability": "readWrite",
              "returned": "default",
              "uniqueness": "none"
            },
            {
              "name": "display",
              "description": "A human-readable name, primarily used for display purposes. UNSUPPORTED",
              "type": "string",
              "multiValued": false,
              "required": false,
              "caseExact": false,
              "mutability": "readWrite",
              "returned": "default",
              "uniqueness": "none"
            },
            {
              "name": "type",
              "description": "A label indicating the certificate''s function. UNSUPPORTED",
              "type": "string",
              "multiValued": false,
              "required": false,
              "caseExact": false,
              "canonicalValues": [],
              "mutability": "readWrite",
              "returned": "default",
              "uniqueness": "none"
            },
            {
              "name": "primary",
              "description": "A Boolean value indicating the preferred attribute value for this attribute. UNSUPPORTED",
              "type": "boolean",
              "multiValued": false,
              "required": false,
              "mutability": "readWrite",
              "returned": "default"
            }
          ]
        }
      ],
      "meta": {
        "resourceType": "Schema",
        "location": "https://scim.frontapp.com/Schemas/urn:ietf:params:scim:schemas:core:2.0:User"
      }
    }
  ]
}'

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $body
})
