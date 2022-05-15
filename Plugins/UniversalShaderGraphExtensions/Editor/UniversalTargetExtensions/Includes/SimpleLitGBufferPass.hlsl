
void InitializeInputData(Varyings input, SurfaceDescription surfaceDescription, out InputData inputData)
{
    inputData = (InputData)0;

    inputData.positionWS = input.positionWS;
    inputData.positionCS = input.positionCS;

    #ifdef _NORMALMAP
        // IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
        float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
        float3 bitangent = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);

        inputData.tangentToWorld = half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz);
        #if _NORMAL_DROPOFF_TS
            inputData.normalWS = TransformTangentToWorld(surfaceDescription.NormalTS, inputData.tangentToWorld);
        #elif _NORMAL_DROPOFF_OS
            inputData.normalWS = TransformObjectToWorldNormal(surfaceDescription.NormalOS);
        #elif _NORMAL_DROPOFF_WS
            inputData.normalWS = surfaceDescription.NormalWS;
        #endif
    #else
        inputData.normalWS = input.normalWS;
    #endif
    inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
    inputData.viewDirectionWS = SafeNormalize(GetWorldSpaceViewDir(input.positionWS));

#if defined(MAIN_LIGHT_CALCULATE_SHADOWS)
    inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
#else
    inputData.shadowCoord = float4(0, 0, 0, 0);
#endif

    inputData.fogCoord = InitializeInputDataFog(float4(input.positionWS, 1.0), input.fogFactorAndVertexLight.x);
    inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
#if defined(DYNAMICLIGHTMAP_ON)
    inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.dynamicLightmapUV.xy, input.sh, inputData.normalWS);
#else
    inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.sh, inputData.normalWS);
#endif
    inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
    inputData.shadowMask = SAMPLE_SHADOWMASK(input.staticLightmapUV);

    #if defined(DEBUG_DISPLAY)
    #if defined(DYNAMICLIGHTMAP_ON)
    inputData.dynamicLightmapUV = input.dynamicLightmapUV.xy;
    #endif
    #if defined(LIGHTMAP_ON)
    inputData.staticLightmapUV = input.staticLightmapUV;
    #else
    inputData.vertexSH = input.sh;
    #endif
    #endif
}

PackedVaryings vert(Attributes input)
{
    Varyings output = (Varyings)0;
    output = BuildVaryings(input);
    PackedVaryings packedOutput = (PackedVaryings)0;
    packedOutput = PackVaryings(output);
    return packedOutput;
}

FragmentOutput frag(PackedVaryings packedInput)
{
    Varyings unpacked = UnpackVaryings(packedInput);
    UNITY_SETUP_INSTANCE_ID(unpacked);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(unpacked);
    SurfaceDescription surfaceDescription = BuildSurfaceDescription(unpacked);

    #if _ALPHATEST_ON
        half alpha = surfaceDescription.Alpha;
        clip(alpha - surfaceDescription.AlphaClipThreshold);
    #elif _SURFACE_TYPE_TRANSPARENT
        half alpha = surfaceDescription.Alpha;
    #else
        half alpha = 1;
    #endif

    InputData inputData;
    InitializeInputData(unpacked, surfaceDescription, inputData);
    // TODO: Mip debug modes would require this, open question how to do this on ShaderGraph.
    //SETUP_DEBUG_TEXTURE_DATA(inputData, unpacked.uv, _MainTex);

    //ifdef _SPECULAR_SETUP
    #ifdef _SPECULAR_COLOR
        float3 specular = surfaceDescription.Specular;
        //float metallic = 1;
    #else
        float3 specular = 0;
        //float metallic = surfaceDescription.Metallic;
    #endif

    // Since we are using SurfaceData in this pass we should include the normal check
    half3 normalTS = half3(0, 0, 0);
    #if defined(_NORMALMAP) && defined(_NORMAL_DROPOFF_TS)
        normalTS = surfaceDescription.NormalTS;
    #endif

#ifdef _DBUFFER
    ApplyDecal(unpacked.positionCS,
        surfaceDescription.BaseColor,
        specular,
        inputData.normalWS,
        /*metallic,*/
        0,
        /*surfaceDescription.Occlusion,*/
        1,
        surfaceDescription.Smoothness);
#endif

    // in SimpleLitForwardPass GlobalIllumination (and temporarily UniversalBlinnPhong) are called inside UniversalFragmentBlinnPhong
    // in Deferred rendering we store the sum of these values (and of emission as well) in the GBuffer
    //BRDFData brdfData;
    //InitializeBRDFData(surfaceDescription.BaseColor, metallic, specular, surfaceDescription.Smoothness, alpha, brdfData);

    SurfaceData surface;
    surface.albedo		= surfaceDescription.BaseColor;
    surface.metallic		= 0.0; //saturate(metallic);
    surface.specular		= specular;
    surface.smoothness		= saturate(surfaceDescription.Smoothness),
    surface.occlusion		= 1.0; //surfaceDescription.Occlusion,
    surface.emission		= surfaceDescription.Emission,
    surface.alpha		= saturate(alpha);
    surface.normalTS		= normalTS;
    surface.clearCoatMask       = 0;
    surface.clearCoatSmoothness = 1;

    Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, inputData.shadowMask);
    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, inputData.shadowMask);
    //half3 color = GlobalIllumination(brdfData, inputData.bakedGI, surfaceDescription.Occlusion, inputData.positionWS, inputData.normalWS, inputData.viewDirectionWS);
    half4 color = half4(inputData.bakedGI * surfaceDescription.BaseColor + surfaceDescription.Emission, surfaceDescription.Alpha);

    //return BRDFDataToGbuffer(brdfData, inputData, surfaceDescription.Smoothness, surfaceDescription.Emission + color, surfaceDescription.Occlusion);
    return SurfaceDataToGbuffer(surface, inputData, color.rgb, kLightingSimpleLit);
}