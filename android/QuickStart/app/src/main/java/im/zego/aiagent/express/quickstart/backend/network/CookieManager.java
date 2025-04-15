package im.zego.aiagent.express.quickstart.backend.network;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import okhttp3.Cookie;
import okhttp3.CookieJar;
import okhttp3.HttpUrl;

public class CookieManager implements CookieJar {

    private static final String TAG = "CookieManager";

    private final HashMap<String, List<Cookie>> cookies = new HashMap<>();

    @Override
    public void saveFromResponse(HttpUrl url, List<Cookie> cookies) {
        this.cookies.put(url.host(), cookies);
    }

    @Override
    public List<Cookie> loadForRequest(HttpUrl url) {
        return cookies.getOrDefault(url.host(), new ArrayList<>());
    }
}