import { Img, staticFile, useCurrentFrame, interpolate } from "remotion";
import { Backdrop, Brand, Motion } from "../design";
export const Closing = () => {
  const f = useCurrentFrame();
  return (
    <Backdrop dark>
      <Img
        src={staticFile("room-campaign.png")}
        style={{
          position: "absolute",
          width: "100%",
          height: "100%",
          objectFit: "cover",
          scale: interpolate(f, [0, 210], [1, 1.04]),
        }}
      />
      <div style={{ position: "absolute", top: 90, left: 110 }}>
        <Brand light />
      </div>
      <div style={{ position: "absolute", left: 110, top: 300, width: 850 }}>
        <Motion>
          <div
            style={{
              fontSize: 112,
              lineHeight: 1.07,
              fontWeight: 800,
              letterSpacing: -6,
            }}
          >
            Make room
            <br />
            for <span style={{ color: "#B9F3D6" }}>a fresh start.</span>
          </div>
        </Motion>
        <Motion delay={15}>
          <div
            style={{
              fontSize: 32,
              marginTop: 34,
              lineHeight: 1.6,
              color: "#E6F5E9",
            }}
          >
            Core cleaning tools work offline.
            <br />
            No account needed.
          </div>
          <div
            style={{
              marginTop: 44,
              display: "inline-block",
              padding: "21px 35px",
              borderRadius: 50,
              background: "#C5F5DB",
              color: "#083F32",
              fontWeight: 800,
              fontSize: 26,
            }}
          >
            Cleanly: Cleaning Checklist
          </div>
        </Motion>
      </div>
    </Backdrop>
  );
};
