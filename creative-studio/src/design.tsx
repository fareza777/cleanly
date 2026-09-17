import React from "react";
import {
  AbsoluteFill,
  Img,
  staticFile,
  useCurrentFrame,
  interpolate,
  Easing,
} from "remotion";
export const P = {
  jade: "#087C62",
  deep: "#073F34",
  mint: "#DDF6E9",
  cream: "#F5F7EE",
  ink: "#112F26",
  gold: "#F4BC65",
};
export const ease = Easing.bezier(0.16, 1, 0.3, 1);
export const Fonts = () => (
  <style>{`@font-face{font-family:Jakarta;src:url("${staticFile("PlusJakartaSans-Regular.ttf")}");font-weight:400}
@font-face{font-family:Jakarta;src:url("${staticFile("PlusJakartaSans-SemiBold.ttf")}");font-weight:600}
@font-face{font-family:Jakarta;src:url("${staticFile("PlusJakartaSans-ExtraBold.ttf")}");font-weight:800}
*{box-sizing:border-box} body{margin:0} `}</style>
);
export const Spark = ({
  size = 48,
  color = "currentColor",
}: {
  size?: number;
  color?: string;
}) => (
  <svg width={size} height={size} viewBox="0 0 100 100">
    <path fill={color} d="M50 4L61 39 96 50 61 61 50 96 39 61 4 50 39 39Z" />
  </svg>
);
export const Mark = ({ size = 56 }: { size?: number }) => (
  <svg width={size} height={size} viewBox="0 0 100 100" fill="currentColor">
    <path d="M49.5 16.5L56.7 39.3 79.5 46.5 56.7 53.7 49.5 76.5 42.3 53.7 19.5 46.5 42.3 39.3Z" />
    <path d="M30 62.5L33 71 41.5 74 33 77 30 85.5 27 77 18.5 74 27 71Z" />
    <path d="M72 23.5L74 29 79.5 31 74 33 72 38.5 70 33 64.5 31 70 29Z" />
  </svg>
);
export const Brand = ({
  light = false,
  small = false,
}: {
  light?: boolean;
  small?: boolean;
}) => (
  <div
    style={{
      display: "flex",
      alignItems: "center",
      gap: 10,
      color: light ? P.mint : P.deep,
      fontSize: small ? 28 : 36,
      fontWeight: 800,
      letterSpacing: -1.5,
    }}
  >
    <Mark size={small ? 40 : 50} />
    Cleanly
    <span
      style={{
        fontWeight: 400,
        fontSize: small ? 17 : 21,
        letterSpacing: 0,
        marginLeft: 10,
        opacity: 0.75,
      }}
    >
      Cleaning Checklist
    </span>
  </div>
);
export const Screen = ({
  name,
  width = 670,
  rotate = 0,
}: {
  name: string;
  width?: number;
  rotate?: number;
}) => (
  <div
    style={{
      width,
      flexShrink: 0,
      padding: 9,
      borderRadius: 42,
      background: "#183D31",
      boxShadow: "0 34px 80px #001F2638, 0 2px 0 #ffffff66 inset",
      rotate: rotate + "deg",
    }}
  >
    <Img
      src={staticFile(name + ".png")}
      style={{ width: "100%", display: "block", borderRadius: 33 }}
    />
  </div>
);
export const Halo = ({ dark = false }: { dark?: boolean }) => (
  <>
    <div
      style={{
        position: "absolute",
        width: 1400,
        height: 1400,
        borderRadius: "50%",
        border: "1px solid " + (dark ? "#9BE0BE22" : "#087C6218"),
        top: 380,
        left: -160,
      }}
    />
    <div
      style={{
        position: "absolute",
        width: 1140,
        height: 1140,
        borderRadius: "50%",
        border: "1px solid " + (dark ? "#9BE0BE22" : "#087C6218"),
        top: 510,
        left: -30,
      }}
    />
  </>
);
export const Backdrop = ({
  dark = false,
  children,
}: {
  dark?: boolean;
  children: React.ReactNode;
}) => (
  <AbsoluteFill
    style={{
      background: dark ? P.deep : P.cream,
      color: dark ? P.cream : P.ink,
      fontFamily: "Jakarta",
      overflow: "hidden",
    }}
  >
    <Fonts />
    <Halo dark={dark} />
    {children}
  </AbsoluteFill>
);
export const Motion = ({
  children,
  delay = 0,
}: {
  children: React.ReactNode;
  delay?: number;
}) => {
  const f = useCurrentFrame();
  return (
    <div
      style={{
        opacity: interpolate(f, [delay, delay + 22], [0, 1], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
        }),
        translate: `0 ${interpolate(f, [delay, delay + 32], [45, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: ease })}px`,
      }}
    >
      {children}
    </div>
  );
};
