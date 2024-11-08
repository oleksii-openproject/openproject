# Custom OpenID Connect providers

> [!IMPORTANT]
> OpenID Connect providers is an Enterprise add-on. If you do not see the button you will have to activate the Enterprise edition first.

Starting in OpenProject 15.0., you can create custom OpenID Connect providers with the user interface [OpenID Providers Authentication Guide](../../../system-admin-guide/authentication/openid-providers/). Please consult this document first for references on all configuration options. Any providers you have created in earlier versions will have been migrated and should be available from the user interface.

However, for some deployment scenarios, it might be desirable to configure a provider through environment variables.

> [!WARNING]
> Only do this if you know what you are doing. Otherwise this may break your existing OpenID Connect authentication or cause other issues.

## Environment variables

The provider entries are defined dynamically based on the environment keys. All variables will start with the prefix
`OPENPROJECT_OPENID__CONNECT_` followed by the provider name. For instance an Okta example would
be defined via environment variables like this:

```shell
OPENPROJECT_OPENID__CONNECT_OKTA_DISPLAY__NAME="Okta"
OPENPROJECT_OPENID__CONNECT_OKTA_HOST="mypersonal.okta.com"
OPENPROJECT_OPENID__CONNECT_OKTA_IDENTIFIER="<identifier or client id>"
# etc.
```

> [!NOTE]
> Underscores in option names must be escaped by doubling them. So make sure to really do use two consecutive underscores in `DISPLAY__NAME`, `TOKEN__ENDPOINT` and so forth



## Configuration

Use the following configuration as a template for your configuration. 

> [!NOTE]
>
> Replace `KEYCLOAK` in the environment name with an alphanumeric identifier. This will become the slug in the redirect URI like follows:
>
> `https://openproject.example.com/auth/keycloak/callback`
>
> You can also see the actual redirect URI in the user interface after the provider has been successfully created from these environment variables.



```bash
# The name of the login button in OpenProject, you can freely set this to anything you like
OPENPROJECT_OPENID__CONNECT_KEYCLOAK_DISPLAY__NAME="Keycloak"

# The Client ID of OpenProject, usually the client host in Keycloak
OPENPROJECT_OPENID__CONNECT_KEYCLOAK_IDENTIFIER="https://<Your OpenProject hostname>"

# The Client Secret used by OpenProject for your provider
OPENPROJECT_OPENID__CONNECT_KEYCLOAK_SECRET="<The client secret you copied from keycloak>"

# The Issuer configuration for your provider
OPENPROJECT_OPENID__CONNECT_KEYCLOAK_ISSUER="https://keycloak.example.com/realms/<REALM>"

# Endpoints for Authorization, Token, Userinfo
OPENPROJECT_OPENID__CONNECT_KEYCLOAK_AUTHORIZATION__ENDPOINT="/realms/<REALM>/protocol/openid-connect/auth"
OPENPROJECT_OPENID__CONNECT_KEYCLOAK_TOKEN__ENDPOINT="/realms/<REALM>/protocol/openid-connect/token"
OPENPROJECT_OPENID__CONNECT_KEYCLOAK_USERINFO__ENDPOINT="/realms/<REALM>/protocol/openid-connect/userinfo"

# Optional: endpoint to redirect users for logout
OPENPROJECT_OPENID__CONNECT_KEYCLOAK_END__SESSION__ENDPOINT="http://keycloak.example.com/realms/<REALM>/protocol/openid-connect/logout"

# Host name of Keycloak, required if endpoint information are not absolute URLs
OPENPROJECT_OPENID__CONNECT_KEYCLOAK_HOST="<Hostname of the keycloak server>"

# Optional: Specify if non-standard port
OPENPROJECT_OPENID__CONNECT_KEYCLOAK_PORT="443"

# Optional: Specify if not using https (only for development/testing purposes)
OPENPROJECT_OPENID__CONNECT_KEYCLOAK_SCHEME="https"

# Optional: Where to redirect the user after a completed logout flow
OPENPROJECT_OPENID__CONNECT_LOCALKEYCLOAK_POST__LOGOUT__REDIRECT__URI="http://example.com"

# Optional: if you have created the client scope mapper as shown above
OPENPROJECT_OPENID__CONNECT_KEYCLOAK_ATTRIBUTE__MAP_LOGIN="preferred_username"

# Optional: Claim mapping using acr_value syntax
OPENPROJECT_OPENID__CONNECT_KEYCLOAK_ACR__VALUES="phr phrh Multi_Factor"

# Optional: Claim mapping using JSON
OPENPROJECT_OPENID__CONNECT_KEYCLOAK_CLAIMS="{\"id_token\":{\"acr\":{\"essential\":true,\"values\":[\"phr\",\"phrh\",\"Multi_Factor\"]}}}"
```



## Applying the configuration

To apply the configuration after changes, you need to run the `db:seed` rake task. In all installations, this command is run automatically when you upgrade or install your application. Use the following commands based on your installation method:

- **Packaged installation**: `sudo openproject run bundle exec rake db:seed`
- **Docker**: `docker exec -it <container of all-in-one or web> bundle exec rake db:seed`.

### Claims

You can also request [claims](https://openid.net/specs/openid-connect-core-1_0-final.html#Claims) for both the id_token and userinfo endpoint.
Mind though that currently only claims requested for the id_token returned with the authorize response are validated.
That is authentication will fail if a requested essential claim is not returned.

#### Requesting MFA authentication via the ACR claim

Say for example that you want to request that the user authenticate using MFA (multi-factor authentication).
You can do this by using the ACR (Authentication Context Class Reference) claim.

This may look different for each identity provider. But if they follow, for instance the [EAP (Extended Authentication Profile)](https://openid.net/specs/openid-connect-eap-acr-values-1_0.html) then the claims would be `phr` (phishing-resistant) and 'phrh' (phishing-resistant hardware-protected). Others may simply have an additional claim called `Multi_Factor`.

You have to check with your identity provider how these values must be called.

In the following example we request a list of ACR values. One of which must be satisfied
(i.e. returned in the ID token by the identity provider, meaning that the requested authentication mechanism was used)
for the login in OpenProject to succeed. If none of the requested claims are present, authentication will fail.

```ruby
options = { ... }

options["claims"] = {
  "id_token": {
    "acr": {
      "essential": true,
      "values": ["phr", "phrh", "Multi_Factor"]
    }
  }
}
```

#### Non-essential claims

You may also request non-essential claims. In the example above this indicates that users should preferably be authenticated using
those mechanisms but it's not strictly required. The login into OpenProject will then work even if none of the claims
are returned by the identity provider.

**The acr_values option**

For non-essential ACR claims you can also use the shorthand form of the option like this:

```ruby
options = { ... }

options["acr_values"] = "phr phrh Multi_Factor"
```

The option takes a space-separated list of ACR values. This is functionally the same as using the
more complicated `claims` option above but with `"essential": false`.

For all other claims there is no such shorthand.

