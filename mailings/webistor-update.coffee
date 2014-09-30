module.exports =

  # The query selector to be used when selecting users from the database.
  selector: {password:null}

  # The header to pass recipients in. Possible values are "to", "cc" or "bcc".
  # CC and BCC are removed before the mail is sent.
  recipientHeader: "bcc"

  # The template directory located within the mail templates folder.
  template: "account/migration-notice"

  # Data generator function. Should return data relevant to the passed-in recipient.
  # Can be an object, in which case all recipients will receive the same data.
  data: (recipient) -> {email:recipient.getAddress()}
