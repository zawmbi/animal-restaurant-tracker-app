# Test suite

Run everything:

```sh
flutter test
```

Run the checkers that need no Flutter toolchain (these also belong in CI, next
to `scripts/validate_data.py` — each exits non-zero on failure):

```sh
python3 scripts/qa_refs.py
python3 scripts/qa_progress_buckets.py
python3 scripts/qa_formatting.py
```

## How these tests are organised

| Directory | Needs a Flutter binding? | Reads assets how? |
|---|---|---|
| `test/models/` | no | `dart:io` straight off disk |
| `test/completion/` | no | `dart:io` straight off disk |
| `test/economy/earnings_calculator_test.dart` | no | nothing — pure arithmetic |
| `test/economy/income_repository_test.dart` | yes | `rootBundle`, via `IncomeRepository` |
| `test/progress/` | yes | `SharedPreferences` mock only |
| `test/widgets/` | yes | `SharedPreferences` mock only |

Model tests read the shipped JSON with `dart:io` rather than `rootBundle` on
purpose. `flutter test` runs with the package root as its working directory, so
`File('assets/data/customers.json')` is the same bytes the app ships, and the
test exercises `fromJson` without dragging in the asset bundle, `compute()`
isolates, or the repository caches.

**Firebase never initialises in a unit test.** `UnlockedStore` imports
`cloud_firestore` and `firebase_auth`, but every Firestore call is behind
`_user != null`, and `_user` is null unless `attachUser` is called with a real
`User`. The tests therefore only exercise guest mode, which is also the mode a
player is in before they sign in. Namespace switching between guest and a uid
cannot be tested here — that needs a fake `User`, which `firebase_auth` does not
provide — so it stays a manual scenario in `docs/qa-report.md`.
