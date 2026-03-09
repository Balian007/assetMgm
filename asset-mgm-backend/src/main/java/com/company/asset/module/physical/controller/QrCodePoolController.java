package com.company.asset.module.physical.controller;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.company.asset.common.result.Result;
import com.company.asset.module.physical.entity.QrCodePool;
import com.company.asset.module.physical.service.QrCodePoolService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;
import java.util.Map;
import cn.hutool.extra.qrcode.QrCodeUtil;
import cn.hutool.core.codec.Base64;

@RestController
@RequestMapping("/api/physical/qr-pool")
@RequiredArgsConstructor
public class QrCodePoolController {

    private final QrCodePoolService qrCodePoolService;

    @PostMapping("/generate")
    public Result<Map<String, String>> generate(@RequestBody Map<String, Integer> request) {
        String batchNo = qrCodePoolService.generateBatch(request.get("count"));
        return Result.ok(Map.of("batchNo", batchNo));
    }

    @PostMapping("/bind")
    public Result<?> bind(@RequestBody Map<String, Object> request) {
        qrCodePoolService.bindToAsset(
            (String) request.get("qrCode"),
            Long.valueOf(request.get("assetId").toString()),
            Long.valueOf(request.getOrDefault("operatorId", 0).toString())
        );
        return Result.ok();
    }

    @GetMapping
    public Result<Page<QrCodePool>> page(@RequestParam(defaultValue = "1") int page,
                                          @RequestParam(defaultValue = "20") int size,
                                          @RequestParam(required = false) String status,
                                          @RequestParam(required = false) String batchNo) {
        QueryWrapper<QrCodePool> qw = new QueryWrapper<>();
        if (status != null) qw.eq("status", status);
        if (batchNo != null) qw.eq("batch_no", batchNo);
        qw.orderByDesc("created_at");
        return Result.ok(qrCodePoolService.page(new Page<>(page, size), qw));
    }

    @GetMapping("/{qrCode}")
    public Result<QrCodePool> getByCode(@PathVariable String qrCode) {
        return Result.ok(qrCodePoolService.getByCode(qrCode));
    }

    @GetMapping("/export/{batchNo}")
    public void exportBatch(@PathVariable String batchNo, HttpServletResponse response) throws IOException {
        List<QrCodePool> list = qrCodePoolService.list(new QueryWrapper<QrCodePool>().eq("batch_no", batchNo));
        response.setContentType("text/html;charset=UTF-8");
        response.setHeader("Content-Disposition", "attachment; filename=" + batchNo + ".html");

        StringBuilder html = new StringBuilder();
        html.append("<!DOCTYPE html><html><head><meta charset='UTF-8'><title>").append(batchNo).append("</title>");
        html.append("<style>body{font-family:Arial;padding:20px;margin:0}");
        html.append(".container{max-width:1200px;margin:0 auto}");
        html.append(".qr-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(180px,1fr));gap:15px;margin-top:20px}");
        html.append(".qr-item{border:1px dashed #999;padding:15px;text-align:center;page-break-inside:avoid}");
        html.append(".qr-item img{display:block;margin:0 auto 10px;width:140px;height:140px}");
        html.append(".qr-text{font-size:12px;word-break:break-all;color:#333}");
        html.append("@media print{body{padding:10px}.qr-item{border:1px solid #000}}</style></head><body>");
        html.append("<div class='container'><h2>批次: ").append(batchNo).append(" (共").append(list.size()).append("个)</h2>");
        html.append("<button onclick='window.print()' style='padding:10px 20px;font-size:14px;cursor:pointer'>打印二维码</button>");
        html.append("<div class='qr-grid'>");

        for (QrCodePool pool : list) {
            byte[] qrBytes = QrCodeUtil.generatePng(pool.getQrCode(), 140, 140);
            String base64 = Base64.encode(qrBytes);
            html.append("<div class='qr-item'><img src='data:image/png;base64,").append(base64).append("'/>");
            html.append("<div class='qr-text'>").append(pool.getQrCode()).append("</div></div>");
        }

        html.append("</div></div></body></html>");
        response.getWriter().write(html.toString());
    }
}
