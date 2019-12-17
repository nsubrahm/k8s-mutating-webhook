const base64 = require('js-base64').Base64;
//
function mutate(admissionReview, callback) {
    // We assume there is no response object in the Admissiont Review request
    let jsonPatch = [{
        op: "replace",
        path: "/spec/containers/0/image",
        value: "debian"
    }]

    // https://github.com/kubernetes/api/blob/7edad22604e1b0437963e77bdf884a331461ed26/admission/v1beta1/types.go#L116
    return callback(null, {
        uid: admissionReview.request.uid,
        allowed: true,
        patch: base64.encode(JSON.stringify(jsonPatch)),
        patchType: "JSONPatch"
    })
}
//
module.exports = { mutate }