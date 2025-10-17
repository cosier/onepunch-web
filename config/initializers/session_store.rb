# Configure session store for both local and tunnel access
if Rails.env.development?
  Rails.application.config.session_store :cookie_store,
    key: '_onepunch_session',
    domain: nil,  # Don't set domain - let browser handle it
    same_site: :lax,  # Allow OAuth redirects
    secure: false,  # Allow both HTTP and HTTPS in dev
    httponly: true,
    expire_after: 2.weeks
else
  Rails.application.config.session_store :cookie_store,
    key: '_onepunch_session',
    same_site: :lax,
    secure: true,
    httponly: true,
    expire_after: 2.weeks
end