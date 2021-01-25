#include "JsVlcVideo.h"

#include "NodeTools.h"
#include "JsVlcPlayer.h"
#include "JsVlcDeinterlace.h"

using namespace v8;

v8::Persistent <v8::Function> JsVlcVideo::_jsConstructor;

void JsVlcVideo::initJsApi() {
    JsVlcDeinterlace::initJsApi();

    using namespace v8;

    Isolate *isolate = Isolate::GetCurrent();
    Local <Context> context = isolate->GetCurrentContext();
    HandleScope scope(isolate);

    Local <FunctionTemplate> constructorTemplate = FunctionTemplate::New(isolate, jsCreate);
    constructorTemplate->SetClassName(
            String::NewFromUtf8(isolate, "VlcVideo", NewStringType::kInternalized).ToLocalChecked());

    Local <ObjectTemplate> protoTemplate = constructorTemplate->PrototypeTemplate();
    Local <ObjectTemplate> instanceTemplate = constructorTemplate->InstanceTemplate();
    instanceTemplate->SetInternalFieldCount(1);

    SET_RO_PROPERTY(instanceTemplate, "tracks", &JsVlcVideo::getTracksArray);
    SET_RO_PROPERTY(instanceTemplate, "count", &JsVlcVideo::count);

    SET_RO_PROPERTY(instanceTemplate, "deinterlace", &JsVlcVideo::deinterlace);

    SET_RW_PROPERTY(instanceTemplate, "track", &JsVlcVideo::track, &JsVlcVideo::setTrack);

    SET_RW_PROPERTY(instanceTemplate, "contrast", &JsVlcVideo::contrast, &JsVlcVideo::setContrast);
    SET_RW_PROPERTY(instanceTemplate, "brightness", &JsVlcVideo::brightness, &JsVlcVideo::setBrightness);
    SET_RW_PROPERTY(instanceTemplate, "hue", &JsVlcVideo::hue, &JsVlcVideo::setHue);
    SET_RW_PROPERTY(instanceTemplate, "saturation", &JsVlcVideo::saturation, &JsVlcVideo::setSaturation);
    SET_RW_PROPERTY(instanceTemplate, "gamma", &JsVlcVideo::gamma, &JsVlcVideo::setGamma);

    Local <Function> constructor = constructorTemplate->GetFunction(context).ToLocalChecked();
    _jsConstructor.Reset(isolate, constructor);
}

Local <Array> JsVlcVideo::getTracksArray() {
    Isolate *isolate = Isolate::GetCurrent();
    Local <Context> context = isolate->GetCurrentContext();

    Local <Array> jsArr = Array::New(isolate, count());
    for (int i = 0; i < jsArr->Length(); i++) {
        jsArr->Set(
                context,
                Integer::New(isolate, i),
                String::NewFromUtf8(isolate, description(i).c_str(), NewStringType::kInternalized).ToLocalChecked()
        );
    }
    return jsArr;
}

std::string JsVlcVideo::description(uint32_t index) {
    vlc_player &p = _jsPlayer->player();

    std::string name;

    libvlc_track_description_t *rootTrackDesc =
            libvlc_video_get_track_description(p.get_mp());
    if (!rootTrackDesc)
        return name;

    unsigned count = _jsPlayer->player().video().track_count();
    if (count && index < count) {
        libvlc_track_description_t *trackDesc = rootTrackDesc;
        for (; index && trackDesc; --index) {
            trackDesc = trackDesc->p_next;
        }

        if (trackDesc && trackDesc->psz_name) {
            name = trackDesc->psz_name;
        }
    }
    libvlc_track_description_list_release(rootTrackDesc);

    return name;
}

v8::UniquePersistent <v8::Object> JsVlcVideo::create(JsVlcPlayer &player) {
    using namespace v8;

    Isolate *isolate = Isolate::GetCurrent();
    Local <Context> context = isolate->GetCurrentContext();

    Local <Function> constructor =
            Local<Function>::New(isolate, _jsConstructor);

    Local <Value> argv[] = {player.handle()};

    return {
            isolate,
            constructor->NewInstance(context, sizeof(argv) / sizeof(argv[0]), argv).ToLocalChecked()
    };
}

void JsVlcVideo::jsCreate(const v8::FunctionCallbackInfo <v8::Value> &args) {
    using namespace v8;

    Isolate *isolate = Isolate::GetCurrent();
    Local <Context> context = isolate->GetCurrentContext();

    Local <Object> thisObject = args.Holder();
    if (args.IsConstructCall() && thisObject->InternalFieldCount() > 0) {
        JsVlcPlayer *jsPlayer =
                ObjectWrap::Unwrap<JsVlcPlayer>(Handle<Object>::Cast(args[0]));
        if (jsPlayer) {
            JsVlcVideo *jsPlaylist = new JsVlcVideo(thisObject, jsPlayer);
            args.GetReturnValue().Set(thisObject);
        }
    } else {
        Local <Function> constructor =
                Local<Function>::New(isolate, _jsConstructor);
        Local <Value> argv[] = {args[0]};
        args.GetReturnValue().Set(
                constructor->NewInstance(context, sizeof(argv) / sizeof(argv[0]), argv).ToLocalChecked());
    }
}

JsVlcVideo::JsVlcVideo(v8::Local <v8::Object> &thisObject, JsVlcPlayer *jsPlayer) :
        _jsPlayer(jsPlayer) {
    Wrap(thisObject);

    _jsDeinterlace = JsVlcDeinterlace::create(*jsPlayer);
}

unsigned JsVlcVideo::count() {
    return _jsPlayer->player().video().track_count();
}

int JsVlcVideo::track() {
    return _jsPlayer->player().video().get_track();
}

void JsVlcVideo::setTrack(unsigned track) {
    _jsPlayer->player().video().set_track(track);
}

double JsVlcVideo::contrast() {
    return _jsPlayer->player().video().get_contrast();
}

void JsVlcVideo::setContrast(double contrast) {
    _jsPlayer->player().video().set_contrast(static_cast<float>(contrast));
}

double JsVlcVideo::brightness() {
    return _jsPlayer->player().video().get_brightness();
}

void JsVlcVideo::setBrightness(double brightness) {
    _jsPlayer->player().video().set_brightness(static_cast<float>(brightness));
}

int JsVlcVideo::hue() {
    return _jsPlayer->player().video().get_hue();
}

void JsVlcVideo::setHue(int hue) {
    _jsPlayer->player().video().set_hue(hue);
}

double JsVlcVideo::saturation() {
    return _jsPlayer->player().video().get_saturation();
}

void JsVlcVideo::setSaturation(double saturation) {
    _jsPlayer->player().video().set_saturation(static_cast<float>(saturation));
}

double JsVlcVideo::gamma() {
    return _jsPlayer->player().video().get_gamma();
}

void JsVlcVideo::setGamma(double gamma) {
    _jsPlayer->player().video().set_gamma(static_cast<float>(gamma));
}

v8::Local <v8::Object> JsVlcVideo::deinterlace() {
    return v8::Local<v8::Object>::New(v8::Isolate::GetCurrent(), _jsDeinterlace);
}
