#!/bin/bash

parse_response_headers () {

g_curl_info=""
g_date=""
g_expires=""
g_cookie=""
g_location=""
g_x_powered_by=""
g_x_powered_cms=""
g_www_auth=""
g_x_frame_options=""
g_x_cto=""
g_x_xssp=""
g_sts=""
g_rp=""
g_csp=""
g_server=""
g_ct=""
g_status=0
g_allow=""
g_x_forwarded_for=""
g_x_forwarded_host=""
g_front_end_https=""
g_x_csrf_token=""
g_x_request_id=""
g_x_tracking_ref=""
g_x_execution_time=""
g_x_envoy_upstream_service_time=""

while IFS=':' read -r key value; do
    # trim whitespace in "value"
    value=${value##+([[:space:]])}; value=${value%%+([[:space:]])}

    case ${key,,} in
        curl)                      g_curl_info="$value" ;;
        date)                      g_date="$value" ;;
        expires)                   g_expires="$value" ;;
        set-cookie)                g_cookie="$value" ;;
        location)                  g_location="$value" ;;
        x-powered-by)              g_x_powered_by="$value" ;;
        x-powered-cms)             g_x_powered_cms="$value" ;;
        www-authenticate)          g_www_auth="$value" ;;
        x-frame-options)           g_x_frame_options="$value" ;;
        x-content-type-options)    g_x_cto="$value" ;;
        x-xss-protection)          g_x_xssp="$value" ;;
        strict-transport-security) g_sts="$value" ;;
        referrer-policy)           g_rp="$value" ;;
        content-security-policy)   g_csp="$value" ;;
        server | webserver)        g_server="$value" ;;
        content-type)              g_ct="$value" ;;
        http*) read -r g_proto g_status g_msg <<< "$key{$value:+:$value}" ;;
        allow)                     g_allow="$value" ;;
        x-forwarded-for)           g_x_forwarded_for="$value" ;;
        x-forwarded-host)          g_x_forwarded_host="$value" ;;
        front-end-https)           g_front_end_https="$value" ;;
        x-csrf-token | x-csrftoken | x-xsrf-token) g_x_csrf_token="$value" ;;
        x-request-id)              g_x_request_id="$value" ;;
        X-Tracking-Ref)            g_x_tracking_ref="$value" ;;
        X-Execution-Time)          g_x_execution_time="$value" ;;
        x-envoy-upstream-service-time) g_x_envoy_upstream_service_time="$value" ;;
     esac
done <<< "$1"

}

parse_current_ip_response () {
# $1 -- variable with curl response
  awk '{print $1}' <<< "$1"
}

get_proto_from_url () {
  awk -F[/:] '{print $1}' <<< "$1"
}

get_hostname_from_url () {
  awk -F[/:] '{print $4}' <<< "$1"
}

get_hostname_wport_from_url () {
  awk -F[/] '{print $3}' <<< "$1"
}

export -f parse_response_headers
export -f parse_current_ip_response
export -f get_proto_from_url
export -f get_hostname_from_url
