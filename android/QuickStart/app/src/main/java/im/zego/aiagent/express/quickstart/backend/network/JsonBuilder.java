package im.zego.aiagent.express.quickstart.backend.network;

import androidx.annotation.NonNull;
import com.google.gson.Gson;
import com.google.gson.JsonObject;

public class JsonBuilder {

    private JsonObject jsonObject;
    private Gson gson;

    public JsonBuilder(Gson gson) {
        jsonObject = new JsonObject();
        this.gson = gson;
    }

    public JsonBuilder() {
        jsonObject = new JsonObject();
    }

    public JsonBuilder addPrimitive(String property, String value) {
        jsonObject.addProperty(property, value);
        return this;
    }

    public JsonBuilder addPrimitive(String property, Number value) {
        jsonObject.addProperty(property, value);
        return this;
    }

    public JsonBuilder addPrimitive(String property, Boolean value) {
        jsonObject.addProperty(property, value);
        return this;
    }

    public JsonBuilder addPrimitive(String property, Character value) {
        jsonObject.addProperty(property, value);
        return this;
    }

    public JsonBuilder addObject(String property, Object value) {
        if (gson == null) {
            throw new RuntimeException("Gson is null");
        }
        jsonObject.add(property, gson.toJsonTree(value));
        return this;
    }

    public String build() {
        return jsonObject.toString();
    }

    @NonNull
    @Override
    public String toString() {
        return build();
    }
}