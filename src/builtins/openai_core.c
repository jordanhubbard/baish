/*
* MIT License
 *
 * Copyright (c) 2025 LunaStev
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#include "openai.h"
#include "openai_internal.h"

#include <stdarg.h>
#include <strings.h>

static const char *openai_default_base_url = "https://api.openai.com/v1";

char* api_key = NULL;
static char* openai_base_url = NULL;
static long openai_timeout_seconds = 0;
static char* openai_last_error = NULL;
static CURL* openai_curl_handle = NULL;

static void
openai_clear_last_error(void)
{
    if (openai_last_error) {
        free(openai_last_error);
        openai_last_error = NULL;
    }
}

static void
openai_set_last_error(const char* fmt, ...)
{
    va_list ap;
    char buf[512];

    openai_clear_last_error();
    if (fmt == NULL)
        return;

    va_start(ap, fmt);
    vsnprintf(buf, sizeof(buf), fmt, ap);
    va_end(ap);

    openai_last_error = strdup(buf);
}

void openai_init(const char* key) {
    if (api_key) free(api_key);
    api_key = key ? strdup(key) : NULL;
    if (openai_base_url == NULL)
        openai_base_url = strdup(openai_default_base_url);
    curl_global_init(CURL_GLOBAL_DEFAULT);
    if (openai_curl_handle == NULL)
        openai_curl_handle = curl_easy_init();
}

void openai_set_base_url(const char* base_url) {
    if (openai_base_url) free(openai_base_url);
    openai_base_url = base_url ? strdup(base_url) : NULL;
}

void openai_set_timeout(long seconds) {
    openai_timeout_seconds = seconds;
}

const char* openai_get_last_error(void) {
    return openai_last_error;
}

void openai_cleanup() {
    if (api_key) free(api_key);
    api_key = NULL;
    if (openai_base_url) free(openai_base_url);
    openai_base_url = NULL;
    openai_clear_last_error();
    if (openai_curl_handle) {
        curl_easy_cleanup(openai_curl_handle);
        openai_curl_handle = NULL;
    }
    curl_global_cleanup();
}

size_t write_callback(void* contents, size_t size, size_t nmemb, void* userp) {
    size_t realsize = size * nmemb;
    struct memory* mem = (struct memory*)userp;

    char* ptr = realloc(mem->response, mem->size + realsize + 1);
    if (!ptr) return 0;

    mem->response = ptr;
    memcpy(&(mem->response[mem->size]), contents, realsize);
    mem->size += realsize;
    mem->response[mem->size] = 0;

    return realsize;
}

char* openai_request_with_status(const char* method, const char* url, const char* body,
                                 long timeout_seconds, long* status)
{
    CURL* curl = openai_curl_handle;
    struct memory chunk = {malloc(1), 0};
    struct curl_slist* headers = NULL;
    CURLcode res;
    long http_status = 0;
    long timeout = timeout_seconds > 0 ? timeout_seconds : openai_timeout_seconds;
    int cleanup_handle = 0;

    openai_clear_last_error();

    if (url == NULL) {
        openai_set_last_error("request url missing");
        free(chunk.response);
        return NULL;
    }

    if (curl == NULL) {
        curl = curl_easy_init();
        if (curl == NULL) {
            openai_set_last_error("curl init failed");
            free(chunk.response);
            return NULL;
        }
        cleanup_handle = 1;
    }

    curl_easy_reset(curl);

    headers = curl_slist_append(headers, "Content-Type: application/json");
    if (api_key && *api_key) {
        char auth_header[512];
        snprintf(auth_header, sizeof(auth_header), "Authorization: Bearer %s", api_key);
        headers = curl_slist_append(headers, auth_header);
    }

    curl_easy_setopt(curl, CURLOPT_URL, url);
    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_callback);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void*)&chunk);
    curl_easy_setopt(curl, CURLOPT_TCP_KEEPALIVE, 1L);

    if (timeout > 0)
        curl_easy_setopt(curl, CURLOPT_TIMEOUT, timeout);

    if (method && strcasecmp(method, "GET") == 0) {
        curl_easy_setopt(curl, CURLOPT_HTTPGET, 1L);
    } else {
        curl_easy_setopt(curl, CURLOPT_POST, 1L);
        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, body ? body : "");
        if (method && strcasecmp(method, "POST") != 0)
            curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, method);
    }

    res = curl_easy_perform(curl);
    if (res != CURLE_OK) {
        openai_set_last_error("curl error: %s", curl_easy_strerror(res));
        free(chunk.response);
        chunk.response = NULL;
    } else {
        curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &http_status);
    }

    if (status)
        *status = http_status;

    curl_slist_free_all(headers);
    if (cleanup_handle)
        curl_easy_cleanup(curl);

    return chunk.response;
}
