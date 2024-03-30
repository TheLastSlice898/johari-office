// Upgrade NOTE: replaced tex2D unity_Lightmap with UNITY_SAMPLE_TEX2D
// Upgrade NOTE: replaced tex2D unity_LightmapInd with UNITY_SAMPLE_TEX2D_SAMPLER

// Made with Amplify Shader Editor v1.9.3.2
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "JohariStandard"
{
	Properties
	{
		_Albedo("Albedo", 2D) = "white" {}
		[Normal]_WoodFloor051_2KPNG_NormalGL("WoodFloor051_2K-PNG_NormalGL", 2D) = "bump" {}
		_WoodFloor051_2KPNG_Roughness("WoodFloor051_2K-PNG_Roughness", 2D) = "white" {}
		_Vector0("Vector 0", Vector) = (1,1,0,0)
		_AmbientOcclusion("AmbientOcclusion", 2D) = "white" {}
		[HideInInspector]_HACKVAL("HACKVAL", Float) = 0
		_Rough("Rough", Range( 0 , 2)) = 1
		_LightMapSpecularBoost("LightMap Specular Boost", Range( 1 , 10)) = 1
		[Toggle]_SMStepSpecs("SMStepSpecs", Float) = 0
		_Height("Height", 2D) = "white" {}
		_Scale("Scale", Float) = 0
		_RefPlane("RefPlane", Float) = 0
		_Metalic("Metalic", 2D) = "black" {}
		_TextureSample12("Texture Sample 12", 2D) = "white" {}
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] _texcoord2( "", 2D ) = "white" {}
		[Header(Parallax Occlusion Mapping)]
		_CurvFix("Curvature Bias", Range( 0 , 1)) = 1
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IsEmissive" = "true"  }
		Cull Back
		CGINCLUDE
		#include "UnityCG.cginc"
		#include "UnityStandardUtils.cginc"
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 5.0
		#ifdef UNITY_PASS_SHADOWCASTER
			#undef INTERNAL_DATA
			#undef WorldReflectionVector
			#undef WorldNormalVector
			#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
			#define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
			#define WorldNormalVector(data,normal) half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))
		#endif
		struct Input
		{
			float2 uv_texcoord;
			float3 viewDir;
			INTERNAL_DATA
			float3 worldNormal;
			float3 worldPos;
			float2 vertexToFrag10_g233;
			float2 uv2_texcoord2;
			float2 vertexToFrag10_g232;
		};

		uniform sampler2D _WoodFloor051_2KPNG_NormalGL;
		uniform float2 _Vector0;
		uniform sampler2D _Height;
		uniform float _Scale;
		uniform float _RefPlane;
		uniform float _CurvFix;
		uniform float4 _Height_ST;
		uniform sampler2D _Albedo;
		uniform sampler2D _TextureSample12;
		uniform float _SMStepSpecs;
		uniform sampler2D _Metalic;
		uniform sampler2D _WoodFloor051_2KPNG_Roughness;
		uniform float _Rough;
		uniform float _HACKVAL;
		uniform float _LightMapSpecularBoost;
		uniform sampler2D _AmbientOcclusion;


		float SchlickFresnel( float i )
		{
			    half x = clamp(1.0-i, 0.0, 1.0);
			    half x2 = x*x;
			    return x2*x2*x;
		}


		inline float2 POM( sampler2D heightMap, float2 uvs, float2 dx, float2 dy, float3 normalWorld, float3 viewWorld, float3 viewDirTan, int minSamples, int maxSamples, int sidewallSteps, float parallax, float refPlane, float2 tilling, float2 curv, int index )
		{
			float3 result = 0;
			int stepIndex = 0;
			int numSteps = ( int )lerp( (float)maxSamples, (float)minSamples, saturate( dot( normalWorld, viewWorld ) ) );
			float layerHeight = 1.0 / numSteps;
			float2 plane = parallax * ( viewDirTan.xy / viewDirTan.z );
			uvs.xy += refPlane * plane;
			float2 deltaTex = -plane * layerHeight;
			float2 prevTexOffset = 0;
			float prevRayZ = 1.0f;
			float prevHeight = 0.0f;
			float2 currTexOffset = deltaTex;
			float currRayZ = 1.0f - layerHeight;
			float currHeight = 0.0f;
			float intersection = 0;
			float2 finalTexOffset = 0;
			while ( stepIndex < numSteps + 1 )
			{
			 	result.z = dot( curv, currTexOffset * currTexOffset );
			 	currHeight = tex2Dgrad( heightMap, uvs + currTexOffset, dx, dy ).r * ( 1 - result.z );
			 	if ( currHeight > currRayZ )
			 	{
			 	 	stepIndex = numSteps + 1;
			 	}
			 	else
			 	{
			 	 	stepIndex++;
			 	 	prevTexOffset = currTexOffset;
			 	 	prevRayZ = currRayZ;
			 	 	prevHeight = currHeight;
			 	 	currTexOffset += deltaTex;
			 	 	currRayZ -= layerHeight * ( 1 - result.z ) * (1+_CurvFix);
			 	}
			}
			int sectionSteps = sidewallSteps;
			int sectionIndex = 0;
			float newZ = 0;
			float newHeight = 0;
			while ( sectionIndex < sectionSteps )
			{
			 	intersection = ( prevHeight - prevRayZ ) / ( prevHeight - currHeight + currRayZ - prevRayZ );
			 	finalTexOffset = prevTexOffset + intersection * deltaTex;
			 	newZ = prevRayZ - intersection * layerHeight;
			 	newHeight = tex2Dgrad( heightMap, uvs + finalTexOffset, dx, dy ).r;
			 	if ( newHeight > newZ )
			 	{
			 	 	currTexOffset = finalTexOffset;
			 	 	currHeight = newHeight;
			 	 	currRayZ = newZ;
			 	 	deltaTex = intersection * deltaTex;
			 	 	layerHeight = intersection * layerHeight;
			 	}
			 	else
			 	{
			 	 	prevTexOffset = finalTexOffset;
			 	 	prevHeight = newHeight;
			 	 	prevRayZ = newZ;
			 	 	deltaTex = ( 1 - intersection ) * deltaTex;
			 	 	layerHeight = ( 1 - intersection ) * layerHeight;
			 	}
			 	sectionIndex++;
			}
			#ifdef UNITY_PASS_SHADOWCASTER
			if ( unity_LightShadowBias.z == 0.0 )
			{
			#endif
			 	if ( result.z > 1 )
			 	 	clip( -1 );
			#ifdef UNITY_PASS_SHADOWCASTER
			}
			#endif
			return uvs.xy + finalTexOffset;
		}


		half3 LightProbeDomDir23(  )
		{
			return float3(unity_SHAr.r,unity_SHAg.g,unity_SHAb.b);
		}


		half3 GGXLight( half3 SpecularCol, float3 worldNrm, half3 lightDir, half3 viewDir, half roughness )
		{
			half roughnessSqr = roughness * roughness;
			        
			// Specular NDF
			    half NdotH = max( 0.0 , ( dot( normalize(viewDir + lightDir), worldNrm) ) );
			    half specAdd = NdotH*NdotH * (roughnessSqr-1.0) + 1.0;
			    half specFinal = roughnessSqr / (UNITY_PI * specAdd*specAdd) ;
			//Specular GSF
			       half NdotL = saturate( dot ( lightDir, worldNrm) );
			       half NdotV = abs( dot ( viewDir , worldNrm) );
			    //half k = roughness / 2;
			       half k = roughness * 0.5;
			       half SmithL = (NdotL)/ (NdotL * (1- k) + k);
			       half SmithV = (NdotV)/ (NdotV * (1- k) + k);
			       half Gs =  (SmithL * SmithV);
			//Specular Fresnell
			     half LdotH = saturate( dot( normalize(viewDir + lightDir),  lightDir) );
			     half3 Schlick =  SpecularCol + (1 - SpecularCol)* SchlickFresnel(LdotH);
			//Specular Combined
			    return  max(0.0, Gs  * specFinal  *  Schlick);
			       
			    
		}


		half3 ShadeSH929( half4 normal )
		{
			return ShadeSH9(half4(normal));
		}


		void vertexDataFunc( inout appdata_full v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			o.vertexToFrag10_g233 = ( ( v.texcoord1.xy * (unity_LightmapST).xy ) + (unity_LightmapST).zw );
			o.vertexToFrag10_g232 = ( ( v.texcoord1.xy * (unity_LightmapST).xy ) + (unity_LightmapST).zw );
		}

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			float2 uv_TexCoord5 = i.uv_texcoord * _Vector0 + float2( 0,0 );
			float3 ase_worldNormal = WorldNormalVector( i, float3( 0, 0, 1 ) );
			float3 ase_worldPos = i.worldPos;
			float3 ase_worldViewDir = Unity_SafeNormalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			float2 OffsetPOM82 = POM( _Height, uv_TexCoord5, ddx(uv_TexCoord5), ddy(uv_TexCoord5), ase_worldNormal, ase_worldViewDir, i.viewDir, 2, 12, 2, _Scale, _RefPlane, _Height_ST.xy, float2(0,0), 0 );
			float3 tex2DNode2 = UnpackNormal( tex2D( _WoodFloor051_2KPNG_NormalGL, OffsetPOM82 ) );
			o.Normal = tex2DNode2;
			float3 temp_cast_0 = (0.0).xxx;
			o.Albedo = temp_cast_0;
			float4 AAAA74 = tex2D( _Albedo, OffsetPOM82 );
			float4 tex2DNode7_g233 = UNITY_SAMPLE_TEX2D( unity_Lightmap, i.vertexToFrag10_g233 );
			float3 decodeLightMap6_g233 = DecodeLightmap(tex2DNode7_g233);
			float3 break94 = decodeLightMap6_g233;
			float2 uv_TexCoord108 = i.uv_texcoord * float2( 0.001,1 ) + float2( 0.15,0 );
			float4 tex2DNode109 = tex2D( _TextureSample12, uv_TexCoord108 );
			float localStochasticTiling2_g230 = ( 0.0 );
			float2 temp_output_56_0 = (i.uv2_texcoord2*(unity_LightmapST).xy + (unity_LightmapST).zw);
			float2 UV2_g230 = temp_output_56_0;
			float localLightmapTexelSize58 = ( 0.0 );
			float4 TexelSize58 = float4( 0,0,0,0 );
			{
			int width = 1, height = 1;
			#if !defined( SHADER_TARGET_SURFACE_ANALYSIS )
			unity_Lightmap.GetDimensions( width, height );
			#endif
			TexelSize58 = float4( 1.0 / float2( width, height ), width, height );
			}
			float4 TexelSize2_g230 = TexelSize58;
			float4 Offsets2_g230 = float4( 0,0,0,0 );
			float2 Weights2_g230 = float2( 0,0 );
			{
			UV2_g230 = UV2_g230 * TexelSize2_g230.zw - 0.5;
			float2 f = frac( UV2_g230 );
			UV2_g230 -= f;
			float4 xn = float4( 1.0, 2.0, 3.0, 4.0 ) - f.xxxx;
			float4 yn = float4( 1.0, 2.0, 3.0, 4.0 ) - f.yyyy;
			float4 xs = xn * xn * xn;
			float4 ys = yn * yn * yn;
			float3 xv = float3( xs.x, xs.y - 4.0 * xs.x, xs.z - 4.0 * xs.y + 6.0 * xs.x );
			float3 yv = float3( ys.x, ys.y - 4.0 * ys.x, ys.z - 4.0 * ys.y + 6.0 * ys.x );
			float4 xc = float4( xv.xyz, 6.0 - xv.x - xv.y - xv.z );
			float4 yc = float4( yv.xyz, 6.0 - yv.x - yv.y - yv.z );
			float4 c = float4( UV2_g230.x - 0.5, UV2_g230.x + 1.5, UV2_g230.y - 0.5, UV2_g230.y + 1.5 );
			float4 s = float4( xc.x + xc.y, xc.z + xc.w, yc.x + yc.y, yc.z + yc.w );
			float w0 = s.x / ( s.x + s.y );
			float w1 = s.z / ( s.z + s.w );
			Offsets2_g230 = ( c + float4( xc.y, xc.w, yc.y, yc.w ) / s ) * TexelSize2_g230.xyxy;
			Weights2_g230 = float2( w0, w1 );
			}
			float4 Input_FetchOffsets197_g231 = Offsets2_g230;
			float2 Input_FetchWeights200_g231 = Weights2_g230;
			float2 break187_g231 = Input_FetchWeights200_g231;
			float4 lerpResult181_g231 = lerp( UNITY_SAMPLE_TEX2D( unity_Lightmap, (Input_FetchOffsets197_g231).yw ) , UNITY_SAMPLE_TEX2D( unity_Lightmap, (Input_FetchOffsets197_g231).xw ) , break187_g231.x);
			float4 lerpResult182_g231 = lerp( UNITY_SAMPLE_TEX2D( unity_Lightmap, (Input_FetchOffsets197_g231).yz ) , UNITY_SAMPLE_TEX2D( unity_Lightmap, (Input_FetchOffsets197_g231).xz ) , break187_g231.x);
			float4 lerpResult176_g231 = lerp( lerpResult181_g231 , lerpResult182_g231 , break187_g231.y);
			float4 Output_Fetch2D202_g231 = lerpResult176_g231;
			float4 temp_output_60_86 = Output_Fetch2D202_g231;
			float4 temp_cast_2 = (0.01).xxxx;
			float4 temp_cast_3 = (1.0).xxxx;
			float4 smoothstepResult65 = smoothstep( temp_cast_2 , temp_cast_3 , temp_output_60_86);
			float4 lerpResult55 = lerp( temp_output_60_86 , smoothstepResult65 , _SMStepSpecs);
			float4 tex2DNode87 = tex2D( _Metalic, OffsetPOM82 );
			float MMMMMg88 = tex2DNode87.r;
			half3 specColor28 = (0).xxx;
			half oneMinusReflectivity28 = 0;
			half3 diffuseAndSpecularFromMetallic28 = DiffuseAndSpecularFromMetallic(AAAA74.rgb,MMMMMg88,specColor28,oneMinusReflectivity28);
			half3 SpecularCol30 = specColor28;
			float3 NNN72 = tex2DNode2;
			half3 worldNrm30 = normalize( (WorldNormalVector( i , NNN72 )) );
			float localStochasticTiling2_g228 = ( 0.0 );
			float2 UV2_g228 = temp_output_56_0;
			float4 TexelSize2_g228 = TexelSize58;
			float4 Offsets2_g228 = float4( 0,0,0,0 );
			float2 Weights2_g228 = float2( 0,0 );
			{
			UV2_g228 = UV2_g228 * TexelSize2_g228.zw - 0.5;
			float2 f = frac( UV2_g228 );
			UV2_g228 -= f;
			float4 xn = float4( 1.0, 2.0, 3.0, 4.0 ) - f.xxxx;
			float4 yn = float4( 1.0, 2.0, 3.0, 4.0 ) - f.yyyy;
			float4 xs = xn * xn * xn;
			float4 ys = yn * yn * yn;
			float3 xv = float3( xs.x, xs.y - 4.0 * xs.x, xs.z - 4.0 * xs.y + 6.0 * xs.x );
			float3 yv = float3( ys.x, ys.y - 4.0 * ys.x, ys.z - 4.0 * ys.y + 6.0 * ys.x );
			float4 xc = float4( xv.xyz, 6.0 - xv.x - xv.y - xv.z );
			float4 yc = float4( yv.xyz, 6.0 - yv.x - yv.y - yv.z );
			float4 c = float4( UV2_g228.x - 0.5, UV2_g228.x + 1.5, UV2_g228.y - 0.5, UV2_g228.y + 1.5 );
			float4 s = float4( xc.x + xc.y, xc.z + xc.w, yc.x + yc.y, yc.z + yc.w );
			float w0 = s.x / ( s.x + s.y );
			float w1 = s.z / ( s.z + s.w );
			Offsets2_g228 = ( c + float4( xc.y, xc.w, yc.y, yc.w ) / s ) * TexelSize2_g228.xyxy;
			Weights2_g228 = float2( w0, w1 );
			}
			float4 Input_FetchOffsets197_g229 = Offsets2_g228;
			float2 Input_FetchWeights200_g229 = Weights2_g228;
			float2 break187_g229 = Input_FetchWeights200_g229;
			float4 lerpResult181_g229 = lerp( UNITY_SAMPLE_TEX2D_SAMPLER( unity_LightmapInd,unity_Lightmap, (Input_FetchOffsets197_g229).yw ) , UNITY_SAMPLE_TEX2D_SAMPLER( unity_LightmapInd,unity_Lightmap, (Input_FetchOffsets197_g229).xw ) , break187_g229.x);
			float4 lerpResult182_g229 = lerp( UNITY_SAMPLE_TEX2D_SAMPLER( unity_LightmapInd,unity_Lightmap, (Input_FetchOffsets197_g229).yz ) , UNITY_SAMPLE_TEX2D_SAMPLER( unity_LightmapInd,unity_Lightmap, (Input_FetchOffsets197_g229).xz ) , break187_g229.x);
			float4 lerpResult176_g229 = lerp( lerpResult181_g229 , lerpResult182_g229 , break187_g229.y);
			float4 Output_Fetch2D202_g229 = lerpResult176_g229;
			half3 localLightProbeDomDir23 = LightProbeDomDir23();
			#ifdef LIGHTMAP_OFF
				float3 staticSwitch50 = localLightProbeDomDir23;
			#else
				float3 staticSwitch50 = ((Output_Fetch2D202_g229).rgb*2.0 + -1.0);
			#endif
			float3 normalizeResult26 = normalize( staticSwitch50 );
			half3 lightDir30 = normalizeResult26;
			half3 viewDir30 = ase_worldViewDir;
			float4 tex2DNode3 = tex2D( _WoodFloor051_2KPNG_Roughness, OffsetPOM82 );
			float RR70 = tex2DNode3.r;
			float temp_output_41_0 = ( RR70 * _Rough );
			half roughness30 = ( temp_output_41_0 * temp_output_41_0 );
			half3 localGGXLight30 = GGXLight( SpecularCol30 , worldNrm30 , lightDir30 , viewDir30 , roughness30 );
			float4 temp_output_53_0 = ( lerpResult55 * float4( localGGXLight30 , 0.0 ) );
			float4 appendResult27 = (float4(localLightProbeDomDir23 , 1.0));
			half4 normal29 = appendResult27;
			half3 localShadeSH929 = ShadeSH929( normal29 );
			#ifdef LIGHTMAP_OFF
				float4 staticSwitch52 = ( ( temp_output_53_0 * _HACKVAL ) + float4( ( localGGXLight30 * max( localShadeSH929 , float3( 0,0,0 ) ) ) , 0.0 ) );
			#else
				float4 staticSwitch52 = temp_output_53_0;
			#endif
			float4 break46 = ( ( staticSwitch52 + float4( 0,0,0,0 ) ) * 5.0 * _LightMapSpecularBoost * 1.0 );
			float2 uv_TexCoord107 = i.uv_texcoord * float2( 0.001,1 );
			float4 tex2DNode106 = tex2D( _TextureSample12, uv_TexCoord107 );
			float3 desaturateInitialColor80 = AAAA74.rgb;
			float desaturateDot80 = dot( desaturateInitialColor80, float3( 0.299, 0.587, 0.114 ));
			float3 desaturateVar80 = lerp( desaturateInitialColor80, desaturateDot80.xxx, 0.0 );
			o.Emission = ( ( AAAA74 * ( ( break94.x * tex2DNode109 * 1.0 ) + ( break46.r * tex2DNode109 * 1.0 ) ) ) + ( ( ( break94.y * tex2DNode106 ) + ( break46.g * tex2DNode106 ) ) * float4( desaturateVar80 , 0.0 ) ) ).rgb;
			o.Metallic = tex2DNode87.r;
			o.Smoothness = ( 1.0 - tex2DNode3.r );
			float4 tex2DNode7_g232 = UNITY_SAMPLE_TEX2D( unity_Lightmap, i.vertexToFrag10_g232 );
			float3 decodeLightMap6_g232 = DecodeLightmap(tex2DNode7_g232);
			float3 desaturateInitialColor12 = decodeLightMap6_g232;
			float desaturateDot12 = dot( desaturateInitialColor12, float3( 0.299, 0.587, 0.114 ));
			float3 desaturateVar12 = lerp( desaturateInitialColor12, desaturateDot12.xxx, 1.0 );
			o.Occlusion = ( saturate( ( desaturateVar12.x * 3.5 ) ) * tex2D( _AmbientOcclusion, OffsetPOM82 ) ).r;
			o.Alpha = 1;
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf Standard keepalpha fullforwardshadows vertex:vertexDataFunc 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 5.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float4 customPack1 : TEXCOORD1;
				float4 customPack2 : TEXCOORD2;
				float4 tSpace0 : TEXCOORD3;
				float4 tSpace1 : TEXCOORD4;
				float4 tSpace2 : TEXCOORD5;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				Input customInputData;
				vertexDataFunc( v, customInputData );
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				half3 worldTangent = UnityObjectToWorldDir( v.tangent.xyz );
				half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				half3 worldBinormal = cross( worldNormal, worldTangent ) * tangentSign;
				o.tSpace0 = float4( worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x );
				o.tSpace1 = float4( worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y );
				o.tSpace2 = float4( worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z );
				o.customPack1.xy = customInputData.uv_texcoord;
				o.customPack1.xy = v.texcoord;
				o.customPack1.zw = customInputData.vertexToFrag10_g233;
				o.customPack2.xy = customInputData.uv2_texcoord2;
				o.customPack2.xy = v.texcoord1;
				o.customPack2.zw = customInputData.vertexToFrag10_g232;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				return o;
			}
			half4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				surfIN.uv_texcoord = IN.customPack1.xy;
				surfIN.vertexToFrag10_g233 = IN.customPack1.zw;
				surfIN.uv2_texcoord2 = IN.customPack2.xy;
				surfIN.vertexToFrag10_g232 = IN.customPack2.zw;
				float3 worldPos = float3( IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w );
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.viewDir = IN.tSpace0.xyz * worldViewDir.x + IN.tSpace1.xyz * worldViewDir.y + IN.tSpace2.xyz * worldViewDir.z;
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = float3( IN.tSpace0.z, IN.tSpace1.z, IN.tSpace2.z );
				surfIN.internalSurfaceTtoW0 = IN.tSpace0.xyz;
				surfIN.internalSurfaceTtoW1 = IN.tSpace1.xyz;
				surfIN.internalSurfaceTtoW2 = IN.tSpace2.xyz;
				SurfaceOutputStandard o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputStandard, o )
				surf( surfIN, o );
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=19302
Node;AmplifyShaderEditor.Vector2Node;7;-1835.555,92.17759;Inherit;False;Constant;_Vector1;Vector 1;3;0;Create;True;0;0;0;False;0;False;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector2Node;6;-1823.555,-73.8224;Inherit;False;Property;_Vector0;Vector 0;5;0;Create;True;0;0;0;False;0;False;1,1;5,5;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.TextureCoordinatesNode;5;-1617.555,23.17759;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FunctionNode;56;-3908.417,2158.393;Inherit;False;Lightmap UV;-1;;216;1940f027d0458684eb0ad486f669d7d5;1,1,0;0;1;FLOAT2;0
Node;AmplifyShaderEditor.CustomExpressionNode;58;-4124.247,2133.833;Inherit;False;int width = 1, height = 1@$#if !defined( SHADER_TARGET_SURFACE_ANALYSIS )$unity_Lightmap.GetDimensions( width, height )@$#endif$TexelSize = float4( 1.0 / float2( width, height ), width, height )@;7;Create;1;True;TexelSize;FLOAT4;0,0,0,0;Out;;Inherit;False;Lightmap Texel Size;False;False;0;;False;2;0;FLOAT;0;False;1;FLOAT4;0,0,0,0;False;2;FLOAT;0;FLOAT4;2
Node;AmplifyShaderEditor.TexturePropertyNode;83;-1257.882,198.9976;Inherit;True;Property;_Height;Height;13;0;Create;True;0;0;0;False;0;False;None;e28255c9f6cd63c44b9cae1e3c9bd7cd;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.RangedFloatNode;84;-1199.53,32.44833;Inherit;False;Property;_Scale;Scale;14;0;Create;True;0;0;0;False;0;False;0;0.04;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;85;-1214.53,401.4483;Inherit;False;Tangent;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;86;-1161.53,663.4484;Inherit;False;Property;_RefPlane;RefPlane;15;0;Create;True;0;0;0;False;0;False;0;0.49;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;47;-4041.294,1930.454;Float;True;Global;unity_LightmapInd;unity_LightmapInd;8;0;Fetch;True;0;0;0;False;0;False;None;None;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.FunctionNode;61;-3691.747,1995.333;Inherit;False;Bicubic Precompute;-1;;228;818835145cc522e4da1f9915d8b8a984;0;2;5;FLOAT2;0,0;False;55;FLOAT4;0,0,0,0;False;2;FLOAT4;34;FLOAT2;54
Node;AmplifyShaderEditor.ParallaxOcclusionMappingNode;82;-876.4149,-34.20952;Inherit;False;0;2;False;;12;False;;2;0.02;0;False;1,1;True;0,0;11;0;FLOAT2;0,0;False;1;SAMPLER2D;;False;7;SAMPLERSTATE;;False;2;FLOAT;0.02;False;3;FLOAT3;0,0,0;False;8;INT;0;False;9;INT;0;False;10;INT;0;False;4;FLOAT;0;False;5;FLOAT2;0,0;False;6;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;3;-577.9775,288.3726;Inherit;True;Property;_WoodFloor051_2KPNG_Roughness;WoodFloor051_2K-PNG_Roughness;4;0;Create;True;0;0;0;False;0;False;-1;8cf4a064e5769c948919e9a2c54148af;dcb69886be4f8874eb274587dff4bd31;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FunctionNode;62;-3413.825,1999.104;Inherit;False;Bicubic Sample;-1;;229;ce0e14d5ad5eac645b2e5892ab3506ff;2,92,2,72,2;7;99;SAMPLER2D;0;False;91;SAMPLER2DARRAY;0;False;93;FLOAT;0;False;97;FLOAT2;0,0;False;198;FLOAT4;0,0,0,0;False;199;FLOAT2;0,0;False;94;SAMPLERSTATE;0;False;5;COLOR;86;FLOAT;84;FLOAT;85;FLOAT;82;FLOAT;83
Node;AmplifyShaderEditor.RegisterLocalVarNode;70;-235.7404,504.1711;Inherit;False;RR;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;2;-583.8533,-94.73926;Inherit;True;Property;_WoodFloor051_2KPNG_NormalGL;WoodFloor051_2K-PNG_NormalGL;3;1;[Normal];Create;True;0;0;0;False;0;False;-1;1d9eba1b04f09df4aa4c9c63f7077256;85967036f3226454e9539a4537141742;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;1;-581.9775,94.37262;Inherit;True;Property;_Albedo;Albedo;0;0;Create;True;0;0;0;False;0;False;-1;6665a7c8446101a41adbe7ccb93d1fdb;17d12231fb2ce7d49a496629c8229956;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ComponentMaskNode;21;-2448.267,1782.391;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;87;185.3278,224.9513;Inherit;True;Property;_Metalic;Metalic;16;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;black;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;71;-2838.318,2181.206;Inherit;False;70;RR;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;22;-2446.927,1850.838;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT;2;False;2;FLOAT;-1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CustomExpressionNode;23;-2608.873,2129.728;Half;False;return float3(unity_SHAr.r,unity_SHAg.g,unity_SHAb.b)@;3;Create;0;LightProbeDomDir;True;False;0;;False;0;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;43;-2876.034,2301.895;Inherit;False;Property;_Rough;Rough;10;0;Create;True;0;0;0;False;0;False;1;1;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;48;-4045.396,1737.221;Float;True;Global;unity_Lightmap;unity_Lightmap;7;0;Fetch;True;0;0;0;False;0;False;None;None;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.FunctionNode;59;-3715.908,1798.258;Inherit;False;Bicubic Precompute;-1;;230;818835145cc522e4da1f9915d8b8a984;0;2;5;FLOAT2;0,0;False;55;FLOAT4;0,0,0,0;False;2;FLOAT4;34;FLOAT2;54
Node;AmplifyShaderEditor.RegisterLocalVarNode;72;-135.1442,44.14084;Inherit;False;NNN;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;74;-154.6082,132.8202;Inherit;False;AAAA;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;88;399.3887,524.1225;Inherit;False;MMMMMg;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;41;-2392.736,2210.088;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;50;-2265.468,1843.79;Float;False;Property;_Keyword7;Keyword 4;16;0;Create;False;0;0;0;False;0;False;0;0;0;False;LIGHTMAP_OFF;Toggle;2;ON;OFF;Fetch;False;True;All;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;60;-3437.986,1802.028;Inherit;False;Bicubic Sample;-1;;231;ce0e14d5ad5eac645b2e5892ab3506ff;2,92,2,72,2;7;99;SAMPLER2D;0;False;91;SAMPLER2DARRAY;0;False;93;FLOAT;0;False;97;FLOAT2;0,0;False;198;FLOAT4;0,0,0,0;False;199;FLOAT2;0,0;False;94;SAMPLERSTATE;0;False;5;COLOR;86;FLOAT;84;FLOAT;85;FLOAT;82;FLOAT;83
Node;AmplifyShaderEditor.RangedFloatNode;63;-2875.497,1598.686;Inherit;False;Constant;_Float27;Float 27;29;0;Create;True;0;0;0;False;0;False;1;0.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;66;-2873.497,1535.686;Inherit;False;Constant;_Float26;Float 26;29;0;Create;True;0;0;0;False;0;False;0.01;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;73;-2472.241,1701.676;Inherit;False;72;NNN;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;75;-2529.054,1585.079;Inherit;False;74;AAAA;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;89;-2541.31,1492.621;Inherit;False;88;MMMMMg;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;24;-2273.373,1704.353;Inherit;False;True;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;25;-2265.468,1939.788;Inherit;False;World;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.NormalizeNode;26;-2070.38,1849.227;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;27;-2355.403,2078.708;Inherit;False;FLOAT4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;1;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;40;-2192.586,2188.418;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;64;-3078.497,1603.686;Inherit;False;Property;_SMStepSpecs;SMStepSpecs;12;1;[Toggle];Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;65;-2776.497,1782.686;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;1,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.DiffuseAndSpecularFromMetallicNode;28;-2326.481,1590.765;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;3;FLOAT3;0;FLOAT3;1;FLOAT;2
Node;AmplifyShaderEditor.CustomExpressionNode;29;-2225.834,2080.448;Half;False;$return ShadeSH9(half4(normal))@;3;Create;1;True;normal;FLOAT4;0,1,0,1;In;;Inherit;False;ShadeSH9;True;False;0;;False;1;0;FLOAT4;0,1,0,1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CustomExpressionNode;30;-1930.469,1770.79;Half;False;$half roughnessSqr = roughness * roughness@$        $// Specular NDF$    half NdotH = max( 0.0 , ( dot( normalize(viewDir + lightDir), worldNrm) ) )@$    half specAdd = NdotH*NdotH * (roughnessSqr-1.0) + 1.0@$    half specFinal = roughnessSqr / (UNITY_PI * specAdd*specAdd) @$$//Specular GSF$       half NdotL = saturate( dot ( lightDir, worldNrm) )@$       half NdotV = abs( dot ( viewDir , worldNrm) )@$    //half k = roughness / 2@$       half k = roughness * 0.5@$       half SmithL = (NdotL)/ (NdotL * (1- k) + k)@$       half SmithV = (NdotV)/ (NdotV * (1- k) + k)@$       half Gs =  (SmithL * SmithV)@$$//Specular Fresnell$     half LdotH = saturate( dot( normalize(viewDir + lightDir),  lightDir) )@$     half3 Schlick =  SpecularCol + (1 - SpecularCol)* SchlickFresnel(LdotH)@$$//Specular Combined$    return  max(0.0, Gs  * specFinal  *  Schlick)@$       $    $$$$;3;Create;5;True;SpecularCol;FLOAT3;0,0,0;In;;Inherit;False;True;worldNrm;FLOAT3;0,0,0;In;;Float;False;True;lightDir;FLOAT3;0,0,0;In;;Inherit;False;True;viewDir;FLOAT3;0,0,0;In;;Half;False;True;roughness;FLOAT;0;In;;Half;False;GGXLight;False;False;0;;False;5;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LerpOp;55;-2691.497,1626.686;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;31;-1688.797,1927.875;Float;False;Property;_HACKVAL;HACKVAL;9;1;[HideInInspector];Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;32;-2058.833,2085.448;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;53;-1745.745,1680.45;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;33;-1680.864,1998.188;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;34;-1563.506,1839.762;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;35;-1423.27,1872.311;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.StaticSwitch;52;-1538.987,1686.479;Float;False;Property;_Keyword13;Keyword 4;16;0;Create;False;0;0;0;False;0;False;0;0;0;False;LIGHTMAP_OFF;Toggle;2;ON;OFF;Fetch;False;True;All;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.FunctionNode;11;-1867.75,-420.2159;Inherit;False;FetchLightmapValue;1;;232;43de3d4ae59f645418fdd020d1b8e78e;0;0;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;13;-1829.75,-323.2159;Inherit;False;Constant;_Float1;Float 1;5;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;36;-1193.234,1917.466;Inherit;False;Constant;_Float23;Float 23;24;0;Create;True;0;0;0;False;0;False;5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;39;-1548.637,2011.276;Inherit;False;Property;_LightMapSpecularBoost;LightMap Specular Boost;11;0;Create;True;0;0;0;False;0;False;1;1;1;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;54;-1320.298,1674.968;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;79;-1314.12,1568.105;Inherit;False;Constant;_Float3;Float 3;12;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DesaturateOpNode;12;-1591.75,-421.2159;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;91;669.0237,92.20773;Inherit;False;FetchLightmapValue;1;;233;43de3d4ae59f645418fdd020d1b8e78e;0;0;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;51;-1180.183,1658.688;Inherit;False;4;4;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;107;-114.7738,820.9729;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;0.001,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TextureCoordinatesNode;108;-180.7738,1094.973;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;0.001,1;False;1;FLOAT2;0.15,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.BreakToComponentsNode;14;-162.0961,-140.2707;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.RangedFloatNode;17;-37.09613,-248.2707;Inherit;False;Constant;_Float2;Float 2;5;0;Create;True;0;0;0;False;0;False;3.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;46;-834.937,1667.881;Inherit;False;COLOR;1;0;COLOR;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.SamplerNode;106;102.7352,823.1277;Inherit;True;Property;_TextureSample12;Texture Sample 12;19;0;Create;True;0;0;0;False;0;False;-1;None;d87af8664dd0ea6439a0a0d9efdddfc5;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.BreakToComponentsNode;94;694.8351,253.3894;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.RangedFloatNode;110;889.4814,425.0396;Inherit;False;Constant;_Float6;Float 6;20;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;109;87.22588,1089.542;Inherit;True;Property;_TextureSample13;Texture Sample 12;19;0;Create;True;0;0;0;False;0;False;-1;None;d87af8664dd0ea6439a0a0d9efdddfc5;True;0;False;white;Auto;False;Instance;106;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;15;23.90387,-128.2707;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;95;1066.88,356.8781;Inherit;False;3;3;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;96;1072.904,545.3678;Inherit;False;3;3;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;100;1079.09,684.4196;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;101;1085.114,872.9093;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;77;1181.994,596.6852;Inherit;False;74;AAAA;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;81;1396.152,706.7231;Inherit;False;Constant;_Float4;Float 4;12;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;16;192.9039,-124.2707;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;19;221.9039,-323.2707;Inherit;True;Property;_AmbientOcclusion;AmbientOcclusion;6;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;93;1084.839,238.944;Inherit;False;74;AAAA;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;102;1235.501,795.6274;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;98;1226.766,457.6613;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.DesaturateOpNode;80;1268.657,916.7983;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;18;484.9039,-135.2707;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;104;1293.353,338.4611;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;105;1394.296,808.7985;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;10;-1827.555,-213.8224;Inherit;False;Constant;_Float0;Float 0;4;0;Create;True;0;0;0;False;0;False;90;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RadiansOpNode;9;-1623.555,-176.8224;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RotatorNode;8;-1300.503,-170.8777;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0.5,0.5;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.OneMinusNode;76;-2595.514,2225.057;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;4;-276.9776,312.3726;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;37;-1920.469,1939.788;Inherit;False;    half x = clamp(1.0-i, 0.0, 1.0)@$    half x2 = x*x@$    return x2*x2*x@;1;Create;1;True;i;FLOAT;0;In;;Inherit;False;SchlickFresnel;False;True;0;;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;49;-3190.774,1984.339;Inherit;True;Property;_TextureSample27;Texture Sample 27;2;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Instance;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;57;-3197.901,1784.216;Inherit;True;Property;_TextureSample28;Texture Sample 28;1;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Instance;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;90;1257.514,-125.1987;Inherit;False;Constant;_Float5;Float 5;16;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;78;1621.514,184.732;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.BreakToComponentsNode;20;684.4645,-120.392;Inherit;False;COLOR;1;0;COLOR;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.ColorNode;97;664.5729,441.5052;Inherit;False;Property;_Color0;Color 0;18;0;Create;True;0;0;0;False;0;False;1,1,1,0;1,1,1,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;99;654.6866,1282.51;Inherit;False;Property;_Color1;Color 1;17;0;Create;True;0;0;0;False;0;False;1,1,1,0;1,1,1,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;1816.018,-83.80212;Float;False;True;-1;7;ASEMaterialInspector;0;0;Standard;JohariStandard;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;;0;False;;False;0;False;;0;False;;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;12;all;True;True;True;True;0;False;;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;2;15;10;25;False;0.5;True;0;0;False;;0;False;;0;0;False;;0;False;;0;False;;0;False;;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;True;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;;-1;0;False;;0;0;0;False;0.1;False;;0;False;;False;17;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;16;FLOAT4;0,0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;5;0;6;0
WireConnection;5;1;7;0
WireConnection;61;5;56;0
WireConnection;61;55;58;2
WireConnection;82;0;5;0
WireConnection;82;1;83;0
WireConnection;82;2;84;0
WireConnection;82;3;85;0
WireConnection;82;4;86;0
WireConnection;3;1;82;0
WireConnection;62;99;47;0
WireConnection;62;198;61;34
WireConnection;62;199;61;54
WireConnection;62;94;47;1
WireConnection;70;0;3;1
WireConnection;2;1;82;0
WireConnection;1;1;82;0
WireConnection;21;0;62;86
WireConnection;87;1;82;0
WireConnection;22;0;21;0
WireConnection;59;5;56;0
WireConnection;59;55;58;2
WireConnection;72;0;2;0
WireConnection;74;0;1;0
WireConnection;88;0;87;1
WireConnection;41;0;71;0
WireConnection;41;1;43;0
WireConnection;50;1;22;0
WireConnection;50;0;23;0
WireConnection;60;99;48;0
WireConnection;60;198;59;34
WireConnection;60;199;59;54
WireConnection;60;94;48;1
WireConnection;24;0;73;0
WireConnection;26;0;50;0
WireConnection;27;0;23;0
WireConnection;40;0;41;0
WireConnection;40;1;41;0
WireConnection;65;0;60;86
WireConnection;65;1;66;0
WireConnection;65;2;63;0
WireConnection;28;0;75;0
WireConnection;28;1;89;0
WireConnection;29;0;27;0
WireConnection;30;0;28;1
WireConnection;30;1;24;0
WireConnection;30;2;26;0
WireConnection;30;3;25;0
WireConnection;30;4;40;0
WireConnection;55;0;60;86
WireConnection;55;1;65;0
WireConnection;55;2;64;0
WireConnection;32;0;29;0
WireConnection;53;0;55;0
WireConnection;53;1;30;0
WireConnection;33;0;30;0
WireConnection;33;1;32;0
WireConnection;34;0;53;0
WireConnection;34;1;31;0
WireConnection;35;0;34;0
WireConnection;35;1;33;0
WireConnection;52;1;53;0
WireConnection;52;0;35;0
WireConnection;54;0;52;0
WireConnection;12;0;11;0
WireConnection;12;1;13;0
WireConnection;51;0;54;0
WireConnection;51;1;36;0
WireConnection;51;2;39;0
WireConnection;51;3;79;0
WireConnection;14;0;12;0
WireConnection;46;0;51;0
WireConnection;106;1;107;0
WireConnection;94;0;91;0
WireConnection;109;1;108;0
WireConnection;15;0;14;0
WireConnection;15;1;17;0
WireConnection;95;0;94;0
WireConnection;95;1;109;0
WireConnection;95;2;110;0
WireConnection;96;0;46;0
WireConnection;96;1;109;0
WireConnection;96;2;110;0
WireConnection;100;0;94;1
WireConnection;100;1;106;0
WireConnection;101;0;46;1
WireConnection;101;1;106;0
WireConnection;16;0;15;0
WireConnection;19;1;82;0
WireConnection;102;0;100;0
WireConnection;102;1;101;0
WireConnection;98;0;95;0
WireConnection;98;1;96;0
WireConnection;80;0;77;0
WireConnection;80;1;81;0
WireConnection;18;0;16;0
WireConnection;18;1;19;0
WireConnection;104;0;93;0
WireConnection;104;1;98;0
WireConnection;105;0;102;0
WireConnection;105;1;80;0
WireConnection;9;0;10;0
WireConnection;8;0;5;0
WireConnection;8;2;9;0
WireConnection;76;0;71;0
WireConnection;4;0;3;1
WireConnection;49;0;47;0
WireConnection;49;1;56;0
WireConnection;57;0;48;0
WireConnection;57;1;56;0
WireConnection;78;0;104;0
WireConnection;78;1;105;0
WireConnection;20;0;18;0
WireConnection;0;0;90;0
WireConnection;0;1;2;0
WireConnection;0;2;78;0
WireConnection;0;3;87;1
WireConnection;0;4;4;0
WireConnection;0;5;20;0
ASEEND*/
//CHKSM=121F7B292C63348DC1B70FDBF2AB2CD6A1B8B46D