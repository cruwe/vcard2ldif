#!/usr/bin/env ruby

IF=ARGV[0]
OF=ARGV[1]

vcard_f = File.new(IF, "r")
ldif_f = File.new(OF, "w")

vcard_lns = []

while (line = vcard_f.gets)

  line.chomp!


  unless line == ""
    unless line =~ /^ /
      vcard_lns.push(line)
    else
      vcard_lns[-1] = vcard_lns[-1] + line.lstrip
    end
  end
end

vcard_f.close


contacts = []
contact = {}

vcard_lns.each do |line|

  if line.include?('BEGIN:VCARD')
    contact = {}
  elsif line.include?('END:VCARD')
    contacts.push(contact)
  else

      key, value = line.chomp.split(':', 2)

      if key.include?('EMAIL')
        if contact['EMAIL'].nil?
          contact['EMAIL'] = []
        end
        contact['EMAIL'].push(value.strip)
      else
        contact[key] = value
      end
  end
end


ldap_a = []

contacts.each do |contact|
  ldap_o = {}

  names_a = contact['N'].split(';',3)
  #names_a[0].gsub!(' ','')

  unless names_a[1].nil?
    names_a[1] = names_a[1].sub(/;*$/,'')
    #names_a[1] = names_a[1].gsub("\"","")
  else
    1+1
  end

  ldap_o['dn'] = "dn: uid=" + names_a[1] + ' ' + names_a[0] + ",ou=addressbook,dc=hb22,dc=cruwe,dc=de"

  ldap_o['objectClass'] = []
  ldap_o['objectClass'].push("inetOrgPerson")
  ldap_o['objectClass'].push("organizationalPerson")
  ldap_o['objectClass'].push("person")

  ldap_o['cn'] = "cn: " + names_a[0]
  ldap_o['sn'] = "sn: " + names_a[0]

  unless ( names_a[1].nil? ||
  names_a[1] == '')
    ldap_o['givenName'] =  "givenName: " + names_a[1]
  end

  ldap_o['mail'] = contact['EMAIL']
  unless ldap_o['mail'].nil?
    ldap_o['mail'].uniq!
  end


  ldap_a.push(ldap_o)
end

ldif_a = []
ldap_a.each do |ldap_o|
  ldif_a.push(ldap_o['dn'])

  ldap_o['objectClass'].each do |objClass|
    ldif_a.push('objectClass: ' + objClass)
  end

    if ( ldap_o.has_key?('mail') &&
         ! ldap_o['mail'].nil?   )
      ldap_o['mail'].each do |mailaddr|
        ldif_a.push('mail: ' + mailaddr)
      end
    end

  ldif_a.push(ldap_o['sn'])
  ldif_a.push(ldap_o['cn'])
  unless ldap_o['givenName'].nil?
    ldif_a.push(ldap_o['givenName'])
  end

  ldif_a.push("")

end

ldif_f.puts(ldif_a)
ldif_f.close

