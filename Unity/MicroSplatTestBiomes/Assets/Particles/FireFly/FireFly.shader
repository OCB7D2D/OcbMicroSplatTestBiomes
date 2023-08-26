Shader "Particles/FireFly"
{
	Properties
	{
		_MainTex("Albedo (Emissive)", 2D) = "white" {}
		_Wings("Wings", 2D) = "white" {}
		_EmissiveAmount("_EmissiveAmount", Float) = 2.0
	}
		SubShader
		{
			Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" }
			LOD 100

			Pass
			{
				CGPROGRAM
				#pragma vertex vert alpha:fade
				#pragma fragment frag
				#pragma multi_compile_particles
				#pragma multi_compile_fog

				#include "UnityCG.cginc"
				float wglnoise_mod289(float x)
				{
					return x - floor(x / 289) * 289;
				}

				float3 wglnoise_permute(float3 x)
				{
					return wglnoise_mod289((x * 34 + 1) * x);
				}

				float4 wglnoise_permute(float4 x)
				{
					return wglnoise_mod289((x * 34 + 1) * x);
				}

				float3 SimplexNoiseGrad(float2 v)
				{
					const float C1 = (3 - sqrt(3)) / 6;
					const float C2 = (sqrt(3) - 1) / 2;

					// First corner
					float2 i = floor(v + dot(v, C2));
					float2 x0 = v - i + dot(i, C1);

					// Other corners
					float2 i1 = x0.x > x0.y ? float2(1, 0) : float2(0, 1);
					float2 x1 = x0 + C1 - i1;
					float2 x2 = x0 + C1 * 2 - 1;

					// Permutations
					i = wglnoise_mod289(i); // Avoid truncation effects in permutation
					float3 p = wglnoise_permute(i.y + float3(0, i1.y, 1));
					p = wglnoise_permute(p + i.x + float3(0, i1.x, 1));

					// Gradients: 41 points uniformly over a unit circle.
					// The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)
					float3 phi = p / 41 * 3.14159265359 * 2;
					float2 g0 = float2(cos(phi.x), sin(phi.x));
					float2 g1 = float2(cos(phi.y), sin(phi.y));
					float2 g2 = float2(cos(phi.z), sin(phi.z));

					// Compute noise and gradient at P
					float3 m = float3(dot(x0, x0), dot(x1, x1), dot(x2, x2));
					float3 px = float3(dot(g0, x0), dot(g1, x1), dot(g2, x2));

					m = max(0.5 - m, 0);
					float3 m3 = m * m * m;
					float3 m4 = m * m3;

					float3 temp = -8 * m3 * px;
					float2 grad = m4.x * g0 + temp.x * x0 +
									m4.y * g1 + temp.y * x1 +
									m4.z * g2 + temp.z * x2;

					return 99.2 * float3(grad, dot(m4, px));
				}

				float SimplexNoise(float2 v)
				{
					return SimplexNoiseGrad(v).z;
				}

				struct appdata
				{
					float4 color : COLOR;
					float4 vertex : POSITION;
					float4 uv : TEXCOORD0;
					float1 customData : TEXCOORD1;
				};

				struct v2f
				{
					float4 color : COLOR;
					float4 vertex : SV_POSITION;
					float4 uv : TEXCOORD0;
					float1 customData : TEXCOORD1;
					UNITY_FOG_COORDS(2)
				};

				sampler2D _MainTex;
				float _EmissiveAmount;
				//float4 _MainTex_ST;

				v2f vert(appdata v)
				{
					v2f o;
					o.uv = v.uv;
					o.customData = v.customData;
					o.color.rgba = v.color.rgba;
					o.vertex = UnityObjectToClipPos(v.vertex);
					UNITY_TRANSFER_FOG(o, o.vertex);
					return o;
				}

				fixed4 frag(v2f i) : SV_Target
				{
					fixed4 col = tex2D(_MainTex, i.uv);
					float4 emissive = i.color * col.a;
					clip(i.color.a - 0.15);
					// col = lerp(col, emissive, pow(abs(SimplexNoise(float2(_Time.x, i.customData.x))), 0.8) * 2.0);
					col *= emissive * pow(abs(SimplexNoise(float2(_Time.x, i.customData.x))) * _EmissiveAmount + 0.5, 2.2);
					UNITY_APPLY_FOG(i.fogCoord, col);
					return col;
				}
				ENDCG
			}

			Pass
			{
				Cull Off
				Blend SrcAlpha OneMinusSrcAlpha

				CGPROGRAM

				#pragma vertex vert
				#pragma fragment frag
				#pragma multi_compile_particles
				#pragma multi_compile_fog

				#include "UnityCG.cginc"

				struct appdata
				{
					float4 vertex : POSITION;
					float4 uv : TEXCOORD0;
					float4 color : COLOR;
				};

				struct v2f
				{
					float4 uv : TEXCOORD0;
					float4 vertex : SV_POSITION;
					float4 color : COLOR;
					UNITY_FOG_COORDS(2)
				};

				sampler2D _Wings;

				v2f vert(appdata v)
				{
					v2f o;
					o.uv = v.uv;
					o.color.rgba = v.color.rgba;
					o.vertex = UnityObjectToClipPos(v.vertex);
					UNITY_TRANSFER_FOG(o, o.vertex);
					return o;
				}

				fixed4 frag(v2f i) : SV_Target
				{
					fixed4 wings = tex2D(_Wings, i.uv.zw);
					wings.a = lerp(wings.a, 0, i.color.a);
					clip(wings.a - 0.15);
					UNITY_APPLY_FOG(i.fogCoord, wings);
					return wings;
				}
				ENDCG

			}
		}
}
