import { Backdrop, Brand, Motion, Screen } from "../design";
export const Progress = () => (
  <Backdrop>
    <div style={{ position: "absolute", top: 75, left: 100 }}>
      <Brand />
    </div>
    <div style={{ position: "absolute", left: 115, top: 285, width: 840 }}>
      <Motion>
        <div
          style={{
            fontSize: 24,
            fontWeight: 800,
            letterSpacing: 4,
            color: "#087C62",
          }}
        >
          04 / NOTICE THE LITTLE WINS
        </div>
        <div
          style={{
            fontSize: 104,
            lineHeight: 1.08,
            fontWeight: 800,
            letterSpacing: -5,
            marginTop: 30,
          }}
        >
          Small cleans.
          <br />
          <span style={{ color: "#087C62" }}>Real progress.</span>
        </div>
      </Motion>
      <Motion delay={12}>
        <div style={{ fontSize: 34, lineHeight: 1.5, marginTop: 35 }}>
          See your minutes, sessions, and streaks.
          <br />
          Progress over perfection.
        </div>
      </Motion>
    </div>
    <div style={{ position: "absolute", right: 180, top: 60 }}>
      <Screen name="history" width={438} />
    </div>
  </Backdrop>
);
