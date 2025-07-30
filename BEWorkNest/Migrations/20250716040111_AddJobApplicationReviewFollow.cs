using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace BEWorkNest.Migrations
{
    /// <inheritdoc />
    public partial class AddJobApplicationReviewFollow : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Benefits",
                table: "JobPosts",
                type: "longtext",
                nullable: false)
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.AddColumn<DateTime>(
                name: "DeadLine",
                table: "JobPosts",
                type: "datetime(6)",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<string>(
                name: "ExperienceLevel",
                table: "JobPosts",
                type: "longtext",
                nullable: false)
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.AddColumn<string>(
                name: "JobType",
                table: "JobPosts",
                type: "longtext",
                nullable: false)
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.AddColumn<string>(
                name: "Requirements",
                table: "JobPosts",
                type: "longtext",
                nullable: false)
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.AlterColumn<int>(
                name: "Status",
                table: "Applications",
                type: "int",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "longtext")
                .OldAnnotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.AddColumn<string>(
                name: "CoverLetter",
                table: "Applications",
                type: "longtext",
                nullable: false)
                .Annotation("MySql:CharSet", "utf8mb4");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Benefits",
                table: "JobPosts");

            migrationBuilder.DropColumn(
                name: "DeadLine",
                table: "JobPosts");

            migrationBuilder.DropColumn(
                name: "ExperienceLevel",
                table: "JobPosts");

            migrationBuilder.DropColumn(
                name: "JobType",
                table: "JobPosts");

            migrationBuilder.DropColumn(
                name: "Requirements",
                table: "JobPosts");

            migrationBuilder.DropColumn(
                name: "CoverLetter",
                table: "Applications");

            migrationBuilder.AlterColumn<string>(
                name: "Status",
                table: "Applications",
                type: "longtext",
                nullable: false,
                oldClrType: typeof(int),
                oldType: "int")
                .Annotation("MySql:CharSet", "utf8mb4");
        }
    }
}
