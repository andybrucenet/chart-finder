# Testing

- Start the app with `npx expo start --localhost` and open the simulator.
- Use the calculator form to add two numbers; expect `Result: <sum>` when the Lambda responds with `{"result": <sum>}`.
- On failure, Expo shows an alert—capture the message and check Metro logs for API errors (auth, network, or payload mismatches).
- Reset the Expo Go cache (dev menu → Developer → Clear cache) before retrying if the bundle appears stale.
