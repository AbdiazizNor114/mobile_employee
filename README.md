# ShaqoNet Employee

Flutter worker mobile app for ShaqoNet.

## Local Checks

```bash
flutter analyze lib test
flutter test
flutter build ios --no-codesign
```

## TestFlight Build

Create a local release config:

```bash
cp .env.testflight.example .env.testflight
```

Fill `.env.testflight` with production-safe public values:

```bash
SHAQONET_API_BASE_URL=https://your-production-api
SHAQONET_SUPABASE_URL=https://your-project.supabase.co
SHAQONET_SUPABASE_ANON_KEY=your-public-anon-key
BUILD_NAME=0.1.0
BUILD_NUMBER=1
```

Build the IPA:

```bash
./scripts/build_testflight.sh
```

The script refuses local API URLs so a TestFlight build cannot accidentally point at `localhost`.
