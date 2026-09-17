import { Backdrop, Brand, Motion, Screen } from "../design";
export const Guided = () => (
  <Backdrop>
    <div style={{ position: "absolute", top: 75, left: 760 }}>
      <Brand />
    </div>
    <div style={{ position: "absolute", left: 150, top: 65 }}>
      <Screen name="session" width={438} rotate={2} />
    </div>
    <div style={{ position: "absolute", left: 760, top: 260, right: 100 }}>
      <Motion>
        <div
          style={{
            fontSize: 24,
            fontWeight: 800,
            letterSpacing: 4,
            color: "#986410",
          }}
        >
          02 / FOLLOW THE NEXT STEP
        </div>
        <div
          style={{
            fontSize: 108,
            lineHeight: 1.05,
            fontWeight: 800,
            letterSpacing: -5,
            marginTop: 30,
          }}
        >
          One task.
          <br />
          <span style={{ color: "#986410" }}>Then the next.</span>
        </div>
      </Motion>
      <Motion delay={15}>
        <div
          style={{
            fontSize: 34,
            lineHeight: 1.5,
            marginTop: 35,
            maxWidth: 900,
          }}
        >
          Check it off. Keep your momentum.
          <br />
          Pause whenever life happens.
        </div>
        <div
          style={{
            display: "inline-block",
            marginTop: 45,
            padding: "18px 28px",
            borderRadius: 50,
            background: "#F9E6BE",
            color: "#795010",
            fontSize: 25,
            fontWeight: 600,
          }}
        >
          No ads during your cleaning timer
        </div>
      </Motion>
    </div>
  </Backdrop>
);
