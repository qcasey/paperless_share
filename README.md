# Paperless Share

An Android app that bridges your document scanner with your [paperless-ng](https://github.com/jonaswinkler/paperless-ng) server.

## Why?

I like using extremely refined scanning apps such as [Office Lens](https://play.google.com/store/apps/details?id=com.microsoft.office.officelens&hl=en_US&gl=US) for documents. **Paperless Share** adds Paperless to the Android share sheet for easy consumption.

It's similar in spirit to [TripleCamel](https://github.com/ebaschiera/TripleCamel), an app that does its job well and can be hidden from your launcher's app list.

## Getting Started

Download [latest release](https://github.com/qcasey/paperless_share/releases/) or build from source.

I might publish on FDroid and Google Play Store, not sure yet.

## Building

Install [Flutter](https://flutter.dev/docs/get-started/install) and [integrate with your IDE of choice](https://flutter.dev/docs/get-started/editor?tab=vscode). A release can then be built and installed using:

```bash
flutter build appbundle
flutter build apk --split-per-abi
cd build/app/outputs/flutter-apk/
flutter install
```

## TODO

* Make PR to https://github.com/bauerj/paperless_app
* Make error handling better and less not-existing
