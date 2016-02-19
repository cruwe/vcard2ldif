#!/usr/bin/env ruby

IN_FILE       =ARGV[0]
OUT_FILE      =ARGV[1]
LDAP_SUBDOMAIN=ARGV[2]

#-------------------------------------------------------------------------
vcard_lines = []
vcard_f = File.open(IN_FILE, 'r')
# read vcard file into array and remove line-breaks in the same data-field
# so that one line maps to one vcard entry
while (ldif_line = vcard_f.gets)
  ldif_line.chomp!

  unless ldif_line == ''
    if ldif_line !~ /^ /
      vcard_lines.push(ldif_line)
    else
      vcard_lines[-1] = vcard_lines[-1] + ldif_line.lstrip
    end
  end
end
vcard_f.close
#-------------------------------------------------------------------------

#-------------------------------------------------------------------------
# map from vcard to ldap keys
vcard2ldap_map = {
    'EMAIL' => 'mail',
    'ADR'   => 'postalAddress',
    'ADR;TYPE=HOME' => 'homePostalAddress',
    'ADR;TYPE=WORK' => 'postalAddress',
    'TEL' => 'telephoneNumber',
    'FAX' => 'facsimileTelephoneNumber'
}
#-------------------------------------------------------------------------

#-------------------------------------------------------------------------
# clean ldap fields, e.g. remove illegal chars
cleanup = {
    'mail' => ->(string) { $1 + '@' + $2 if string =~ /([a-zA-Z0-9\.\-]+)@([a-zA-Z0-9\.\-]+)/ },
    'telephoneNumber' => ->(string) {
      string.gsub!(/[ \/\-\(\)]+/,'')
      string.gsub!(/^00/,'+')
      string.gsub(/(^0)([1-9])([0-9])/, '+49\2\3')
    },
    'facsimileTelephoneNumber' => ->(string) { string.gsub(/[ ]+/,'') },
    'homePostalAddress' => ->(string) {
      string.gsub!(';',' ')
      string.gsub('\n','').squeeze(' ')
    },
    'postalAddress' => ->(string) {string.gsub(';',' ').squeeze(' ')}
}
#-------------------------------------------------------------------------


#-------------------------------------------------------------------------
vcards = []
vcard = {}
non_uniq_types = %w(EMAIL FAX TEL)

# iter through lines in vcard file
# chop into individual contact data sets
# extract relevant attributes
# store all attrs as vcard hash map (vcard_type,vcard_val)
vcard_lines.each do |line|

  if line.include?('BEGIN:VCARD')
    # at beginning, do nothing
  elsif line.include?('END:VCARD')
    # at end, store and reset vcard
    vcards.push(vcard)
    vcard = {}
  else
    # split in (vcard_type,vcard_val) pairs
    vcard_type, vcard_val = line.split(':', 2)
    vcard_type.upcase!

    # some types allow for multiple entries
    # check if type is one of those and if true, iter through this array of
    # entries and push to array. if false, treat as single, unique pair
    if non_uniq_types.any? { |nu_type|
      if vcard_type.start_with?(nu_type)
        if vcard[nu_type].nil?
          vcard[nu_type] = []
        end
        vcard[nu_type].push(vcard_val.strip)
      end
    }
    else
      vcard[vcard_type] = vcard_val.strip
    end
  end
end
#-------------------------------------------------------------------------

#-------------------------------------------------------------------------
# iter through all vcards and build ldap_obj from every vcard
ldap_objs = []
vcards.each do |vcard|
  ldap_obj = {}

  names_a = vcard['N'].split(';')

  ldap_obj['dn'] = 'uid=' + names_a[0 .. 1].join(' ') + ',' + LDAP_SUBDOMAIN
  ldap_obj['objectClass'] = %w(inetOrgPerson organizationalPerson person)
  ldap_obj['sn'] = names_a[0]
  ldap_obj['cn'] = names_a[0]
  unless names_a[1].nil? ||
         names_a[1] == ''
    ldap_obj['givenName'] =  names_a[1]
  end

  vcard.each do |vcard_key, vcard_val|

    ldap_key = vcard2ldap_map[vcard_key]
    # ldap_val = vcard_val because we do not transform, only clean

    unless ldap_key.nil?

      if vcard_val.is_a?(Array)
        values = []
        vcard_val.each do |value|
          tmp = cleanup[ldap_key].call(value)
          values.push(tmp)
        end
        ldap_obj[ldap_key] = values
      else
        tmp = cleanup[ldap_key].call(vcard_val)
        ldap_obj[ldap_key] = tmp
      end
    end
  end

  ldap_objs.push(ldap_obj)
end


ldif_f = File.new(OUT_FILE, 'w')
ldap_objs.each do |ldap_obj|

  ldap_obj.each do |ldap_key, ldap_value|

    if ldap_value.kind_of?(Array)
      ldap_value.each do |value|
        ldif_line = ldap_key + ': ' + value
        ldif_f.puts(ldif_line)
        puts(ldif_line)
      end
    else
      ldif_line = ldap_key + ': ' + ldap_value
      ldif_f.puts(ldif_line)
      puts(ldif_line)

    end



  end
  ldif_f.puts ''
  puts ''
end

ldif_f.close

