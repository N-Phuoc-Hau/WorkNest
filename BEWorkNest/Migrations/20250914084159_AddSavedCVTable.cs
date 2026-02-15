using System;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace BEWorkNest.Migrations
{
    /// <inheritdoc />
    public partial class AddSavedCVTable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "CVFileName",
                table: "CVAnalysisHistories",
                type: "longtext",
                nullable: true)
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.AddColumn<long>(
                name: "CVFileSize",
                table: "CVAnalysisHistories",
                type: "bigint",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "CVPublicId",
                table: "CVAnalysisHistories",
                type: "longtext",
                nullable: true)
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.AddColumn<string>(
                name: "CVUrl",
                table: "CVAnalysisHistories",
                type: "longtext",
                nullable: true)
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.AddColumn<int>(
                name: "SavedCVId",
                table: "Applications",
                type: "int",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "SavedCVs",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("MySql:ValueGenerationStrategy", MySqlValueGenerationStrategy.IdentityColumn),
                    UserId = table.Column<string>(type: "varchar(255)", nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Name = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Description = table.Column<string>(type: "varchar(500)", maxLength: 500, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    FilePath = table.Column<string>(type: "longtext", nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    FileName = table.Column<string>(type: "varchar(50)", maxLength: 50, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    FileExtension = table.Column<string>(type: "varchar(10)", maxLength: 10, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    FileSize = table.Column<long>(type: "bigint", nullable: false),
                    ExtractedText = table.Column<string>(type: "text", nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Skills = table.Column<string>(type: "text", nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    WorkExperience = table.Column<string>(type: "text", nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Education = table.Column<string>(type: "text", nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Projects = table.Column<string>(type: "text", nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Certifications = table.Column<string>(type: "text", nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Languages = table.Column<string>(type: "text", nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    ExperienceYears = table.Column<int>(type: "int", nullable: true),
                    CurrentPosition = table.Column<string>(type: "longtext", nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    IsDefault = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    IsActive = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    OverallScore = table.Column<int>(type: "int", nullable: true),
                    AnalysisResult = table.Column<string>(type: "text", nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    LastAnalyzedAt = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    UsageCount = table.Column<int>(type: "int", nullable: false),
                    LastUsedAt = table.Column<DateTime>(type: "datetime(6)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SavedCVs", x => x.Id);
                    table.ForeignKey(
                        name: "FK_SavedCVs_AspNetUsers_UserId",
                        column: x => x.UserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateIndex(
                name: "IX_Applications_SavedCVId",
                table: "Applications",
                column: "SavedCVId");

            migrationBuilder.CreateIndex(
                name: "IX_SavedCVs_CreatedAt",
                table: "SavedCVs",
                column: "CreatedAt");

            migrationBuilder.CreateIndex(
                name: "IX_SavedCVs_IsActive",
                table: "SavedCVs",
                column: "IsActive");

            migrationBuilder.CreateIndex(
                name: "IX_SavedCVs_IsDefault",
                table: "SavedCVs",
                column: "IsDefault");

            migrationBuilder.CreateIndex(
                name: "IX_SavedCVs_UserId",
                table: "SavedCVs",
                column: "UserId");

            migrationBuilder.AddForeignKey(
                name: "FK_Applications_SavedCVs_SavedCVId",
                table: "Applications",
                column: "SavedCVId",
                principalTable: "SavedCVs",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Applications_SavedCVs_SavedCVId",
                table: "Applications");

            migrationBuilder.DropTable(
                name: "SavedCVs");

            migrationBuilder.DropIndex(
                name: "IX_Applications_SavedCVId",
                table: "Applications");

            migrationBuilder.DropColumn(
                name: "CVFileName",
                table: "CVAnalysisHistories");

            migrationBuilder.DropColumn(
                name: "CVFileSize",
                table: "CVAnalysisHistories");

            migrationBuilder.DropColumn(
                name: "CVPublicId",
                table: "CVAnalysisHistories");

            migrationBuilder.DropColumn(
                name: "CVUrl",
                table: "CVAnalysisHistories");

            migrationBuilder.DropColumn(
                name: "SavedCVId",
                table: "Applications");
        }
    }
}
