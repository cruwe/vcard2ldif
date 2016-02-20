# vcard2ldif

The vcard format as  specified by the [vCard and CardDAV Working Group](https://tools.ietf.org/wg/vcarddav/) is quickly becoming the de-facto standard to exchange and 
store contact information, which formerly has been an 
exclusive domain of directory servers, most prominently of the LDAP family.

In the absence of reliable methods for prognosis it is unclear if and if,
for how long, the vcard standard will or can coexist with existing LDAP 
installations. Judging by [the number of relevant RFCs](https://en.wikipedia.org/wiki/Lightweight_Directory_Access_Protocol#RFCs), LDAP is still 
leading with vcard gaining ground.

Numerous tools exist to convert LDAP information to vcard. I have found 
none to do the reverse, _i.e._ extracting information from vcards for 
storage in LDAP servers. This tool redresses the situation for a specific 
subset of entries. Extension and pull requests are welcome. 

# vcard2ldif.rb(1)

NAME

vcard2ldif.rb - convert vcards to ldif representation of LDAP 
 
SYNOPSIS 

vcard2ldif.rb _inputfile_ _outputfile_ _ldapdomain_ 

DESCRIPTION

vcard2ldif.rb parses a _inputfile_ [text/plain] containing one or more 
vcards. It then extracts a subset of attributes (name, addresses, phone
numbers and email addresses) from the vcard and prints these as 
LDIF-formatted elements to an _outputfile_ [text/plain]. Each identifying 
LDAP element 'dn' is constructed by appending the (unique) name of a 
contact with the _ldap_subdomain_ as in dn=Mickey Mouse,ou=addresses,
dc=example,dc=org.
