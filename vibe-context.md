## Sandbox

You are running inside a Docker sandbox (sbx). The working directory is the
user's project, mounted from the host.

`MISTRAL_API_KEY` holds a sentinel value, not the real key: the sandbox proxy
swaps in the real one on requests to Mistral. Do not read, print or
reconfigure it.

Outbound network access is restricted to the hosts this kit declares. If a
command fails with an HTTP 403 from the proxy, the host is not allowed; tell
the user rather than working around it.
