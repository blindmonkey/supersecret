lib.export('format', (string, subs...) ->
  output = ''
  argumentIndex = 0
  formatString = null
  for i in [0..string.length-1]
    char = string[i]
    if char == '%'
      formatString = ''
    else if formatString?
      if char == 'd'
        output += Math.floor(subs[argumentIndex++])
        formatString = null
      else if char == 'f'
        output += subs[argumentIndex++]
        formatString = null
      else if char == 's'
        output += subs[argumentIndex++]
        formatString = null
      else
        formatString += char
    else
      output += char
  return output
)
