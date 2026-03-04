package com.company.asset;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@MapperScan("com.company.asset.module.**.mapper")
@EnableScheduling
public class AssetMgmApplication {
    public static void main(String[] args) {
        SpringApplication.run(AssetMgmApplication.class, args);
    }
}
