flutter clean
flutter pub get
flutter build ios --release --no-codesign

mkdir -p Payload
cp -r build/ios/iphoneos/Runner.app Payload/
zip -r MyApp.ipa Payload
rm -rf Payload
