request = urllib.request.Request(
    f"https://www.curseforge.com/api/projects/{project}/upload-file",
    data=body,
    headers={
        "X-Api-Token": token,
        "Content-Type": f"multipart/form-data; boundary={boundary}"
    },
    method="POST"
)

try:
    with urllib.request.urlopen(request, timeout=120) as response:
        print("Response Status:", response.status)
        print("Response Headers:", dict(response.headers))
        result = json.load(response)

except urllib.error.HTTPError as error:
    print("\n=== CurseForge Error ===")
    print("HTTP Status:", error.code)
    print("Reason:", error.reason)

    try:
        response_body = error.read().decode("utf-8", errors="replace")
        print("Response Body:")
        print(response_body)
    except Exception as ex:
        print("Could not decode response:", ex)

    raise

except Exception as ex:
    print("\n=== Unexpected Error ===")
    print(type(ex).__name__)
    print(str(ex))
    raise

print("Submitted CurseForge file ID:", result.get("id", "unknown"))
print("Full Response:")
print(json.dumps(result, indent=2))
