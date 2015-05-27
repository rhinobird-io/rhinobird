class EmailQueue
  @queue = :notifiers

  def self.perform(from, to, subject, body)
      Mail.deliver do
        from from
        to to
        subject subject
        content_type 'text/html; charset=UTF-8'
        body body
      end
  end
end