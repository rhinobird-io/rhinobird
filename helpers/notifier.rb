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


def notify(user, notify, subject, body)
  if settings.sockets[user.id].nil?
    # puts 'Email Notification'
    Resque.enqueue(EmailQueue, 'rhinobird.worksap@gmail.com', 'li_ju@worksap.co.jp', subject, body)
  else
    settings.sockets[user.id].send(notify)
  end
end