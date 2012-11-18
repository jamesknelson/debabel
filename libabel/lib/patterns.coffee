# Each pattern is represented by a document in the Patterns collection:
#
# audio: data
# structure:  
#   [ {pronunce: string, spell: string, audio: slice reference}
#  or {placeholder} ]
# composition:
#   [ {location: stucture indexes, source: patternId, 
#    , spellTransform, pronunceTransform}]
#    , confirmed: Boolean} ]
#   or
#   [{grammar: grammarId, location, confirmed: Boolean}]
#
# published?:         
#   Boolean
# type:
#   "subatomic": Part of an expression not used by itself. Used
#                for scheduling only. Characters are often subatomic.
#   "normal":    An expression with more meaning than the components 
#                capture. Used for examples and scheduling.
#   "compound":  An expression which doesn't add any more meaning to
#                it's components. Used for examples only.
# language:       
#   2-character language code (eg. EN, JP)
# history:
#   Array of changes and who they made them. Includes initial source.
#
# explanations:
#   [{type: dictionary, language: 2-character code,
#     value: String with dictionary meaning (optional, non-public)}
#    {type: image, ...}
#    etc.]

Patterns = new Meteor.Collection "patterns"

# TODO: limit to admins
Patterns.allow
  # Don't allow remote inserts, must use createExpression
  insert: (userId, expression) -> false
  update: (userId, patterns, fields, modifier) -> true
    # A good improvement would be to validate the type of the new
    # value of the field (and if a string, the length.) In the
    # future Meteor will have a schema system to makes that easier.

    # false if userId != an admin user id
  remove: (userId, patterns) -> true
    # Validations could go here too in the future

    # false if userId != an admin user id

Meteor.methods
  createExpression: (o) ->
    o ||= {}

    # TODO: check more thorougly, check structure of compotision, explanations
    unless typeof o.language == "string" && o.language.length == 2 &&
           typeof o.pronunciation == "string" && o.pronunciation.length &&
           typeof o.spelling == "string" && o.spelling.length &&
           typeof o.source == "string" && o.source.length &&
           typeof o.published == "boolean" || o.published == undefined
      throw new Meteor.Error 400, "Required parameter missing"

    #if (o.title.length > 100)
    #  throw new Meteor.Error(413, "Title too long");
    #if (o.description.length > 1000)
    #  throw new Meteor.Error(413, "Description too long");
    
    unless this.userId
      throw new Meteor.Error 403, "You must be logged in"

    Patterns.insert
      published: !! o.published
      source: o.source
      language: o.language
      pronunciation: o.pronunciation
      spelling: o.spelling
      audio: []
      composition: [] || o.composition
      explanations: [] || o.explanations
