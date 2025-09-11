using System;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace BEWorkNest.Migrations
{
    /// <inheritdoc />
    public partial class AddCVAnalysisStats : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "CVAnalysisHistories",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("MySql:ValueGenerationStrategy", MySqlValueGenerationStrategy.IdentityColumn),
                    AnalysisId = table.Column<string>(type: "varchar(255)", nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    UserId = table.Column<string>(type: "varchar(255)", nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    CVText = table.Column<string>(type: "longtext", nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    AnalysisResult = table.Column<string>(type: "longtext", nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    OverallScore = table.Column<int>(type: "int", nullable: false),
                    JobRecommendationsCount = table.Column<int>(type: "int", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CVAnalysisHistories", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CVAnalysisHistories_AspNetUsers_UserId",
                        column: x => x.UserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "CVAnalysisStats",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("MySql:ValueGenerationStrategy", MySqlValueGenerationStrategy.IdentityColumn),
                    UserId = table.Column<string>(type: "varchar(255)", nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    TotalAnalyses = table.Column<int>(type: "int", nullable: false),
                    AverageScore = table.Column<double>(type: "double", nullable: false),
                    HighestScore = table.Column<int>(type: "int", nullable: false),
                    LowestScore = table.Column<int>(type: "int", nullable: false),
                    TotalJobRecommendations = table.Column<int>(type: "int", nullable: false),
                    FirstAnalysisDate = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    LastAnalysisDate = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CVAnalysisStats", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CVAnalysisStats_AspNetUsers_UserId",
                        column: x => x.UserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "JobMatchAnalytics",
                columns: table => new
                {
                    JobId = table.Column<int>(type: "int", nullable: false),
                    UserId = table.Column<string>(type: "varchar(255)", nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    MatchScore = table.Column<int>(type: "int", nullable: false),
                    MatchDetails = table.Column<string>(type: "longtext", nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    AnalyzedAt = table.Column<DateTime>(type: "datetime(6)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_JobMatchAnalytics", x => new { x.JobId, x.UserId });
                    table.ForeignKey(
                        name: "FK_JobMatchAnalytics_AspNetUsers_UserId",
                        column: x => x.UserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_JobMatchAnalytics_JobPosts_JobId",
                        column: x => x.JobId,
                        principalTable: "JobPosts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateIndex(
                name: "IX_CVAnalysisHistories_AnalysisId",
                table: "CVAnalysisHistories",
                column: "AnalysisId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_CVAnalysisHistories_CreatedAt",
                table: "CVAnalysisHistories",
                column: "CreatedAt");

            migrationBuilder.CreateIndex(
                name: "IX_CVAnalysisHistories_UserId",
                table: "CVAnalysisHistories",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_CVAnalysisStats_UpdatedAt",
                table: "CVAnalysisStats",
                column: "UpdatedAt");

            migrationBuilder.CreateIndex(
                name: "IX_CVAnalysisStats_UserId",
                table: "CVAnalysisStats",
                column: "UserId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_JobMatchAnalytics_AnalyzedAt",
                table: "JobMatchAnalytics",
                column: "AnalyzedAt");

            migrationBuilder.CreateIndex(
                name: "IX_JobMatchAnalytics_MatchScore",
                table: "JobMatchAnalytics",
                column: "MatchScore");

            migrationBuilder.CreateIndex(
                name: "IX_JobMatchAnalytics_UserId",
                table: "JobMatchAnalytics",
                column: "UserId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "CVAnalysisHistories");

            migrationBuilder.DropTable(
                name: "CVAnalysisStats");

            migrationBuilder.DropTable(
                name: "JobMatchAnalytics");
        }
    }
}
