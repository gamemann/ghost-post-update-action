#!/bin/bash

if [[ -z "$API_URL" ]]; then
    echo "API URL not specified!"

    exit 1
fi

if [[ -z "$ADMIN_API_KEY" ]]; then
    echo "Admin API key not specified!"

    exit 1
fi

if [[ -z "$POST_ID" ]]; then
    echo "Post ID not specified!"

    exit 1
fi

# Process test Markdown file.
./scripts/process_contents.sh ".env" "test.md" "4" > tmp.md

CONTENTS_JSON=$(jq -Rs . tmp.md)

# Generate Ghost token.
TMPIFS=$IFS
IFS=':' read ID SECRET <<< "$ADMIN_API_KEY"
IFS=$TMPIFS

# Prepare header and payload
NOW=$(date +'%s')
FIVE_MINS=$(($NOW + 300))
HEADER="{\"alg\": \"HS256\",\"typ\": \"JWT\", \"kid\": \"$ID\"}"
PAYLOAD="{\"iat\":$NOW,\"exp\":$FIVE_MINS,\"aud\": \"/admin/\"}"

# Helper function for performing base64 URL encoding
base64_url_encode() {
    declare input=${1:-$(</dev/stdin)}
    # Use `tr` to URL encode the output from base64.
    printf '%s' "${input}" | base64 | tr -d '=' | tr '+' '-' | tr '/' '_' | tr -d '\n' 
}

# Prepare the token body
header_base64=$(base64_url_encode "${HEADER}")
payload_base64=$(base64_url_encode "${PAYLOAD}")

header_payload="${header_base64}.${payload_base64}"

# Create the signature
signature=$(printf '%s' "${header_payload}" | openssl dgst -binary -sha256 -mac HMAC -macopt hexkey:$SECRET | base64_url_encode)

# A token!
TOKEN="${header_payload}.${signature}"

# Retrieve updated at.
resp=$(curl -s -H "Authorization: Ghost $TOKEN" "$API_URL/posts/$POST_ID/?formats=lexical")
updated_at=$(echo "$resp" | jq -r '.posts[0].updated_at')

# We need to double escape the JSON contents.
ESCAPED_CONTENTS_JSON=$(echo "$CONTENTS_JSON" | sed 's/\\/\\\\/g; s/"/\\"/g')

# Generate JSON payload.
json_payload=$(cat <<EOF
{
  "posts": [
    {
      "lexical": "{\\"root\\":{\\"children\\":[{\\"type\\":\\"markdown\\",\\"version\\":1,\\"markdown\\":$ESCAPED_CONTENTS_JSON},{\\"children\\":[],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"paragraph\\",\\"version\\":1}],\\"direction\\":null,\\"format\\":\\"\\",\\"indent\\":0,\\"type\\":\\"root\\",\\"version\\":1}}",
      "updated_at": "$updated_at"
    }
  ]
}
EOF
)

echo "Updating post at: $API_URL/posts/$POST_ID"
echo "Admin API: $ADMIN_API_KEY"
echo "Token: $TOKEN"
echo "Updated At: $updated_at"
echo "JSON Payload:"
echo

echo "$json_payload"

# Update post.
resp=$(curl -v -X PUT "$API_URL/posts/$POST_ID" \
          -H "Authorization: Ghost $TOKEN" \
          -H "Content-Type: application/json" \
          -H "Accept-Version: v5.130" \
          -d "$json_payload")

echo $resp